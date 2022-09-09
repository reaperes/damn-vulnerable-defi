# Damn vulnerable defi CTF challenges

1. [Unstoppable](https://github.com/reaperes/damn-vulnerable-defi#unstoppable)
2. [Naive receiver](https://github.com/reaperes/damn-vulnerable-defi#naive-receiver)
3. [Truster](https://github.com/reaperes/damn-vulnerable-defi#truster)
4. [Side entrance](https://github.com/reaperes/damn-vulnerable-defi#side-entrance)
5. [The rewarder](https://github.com/reaperes/damn-vulnerable-defi#the-rewarder)
6. [Selfie](https://github.com/reaperes/damn-vulnerable-defi#selfie)
7. [Compromised](https://github.com/reaperes/damn-vulnerable-defi#compromised)
8. [Puppet](https://github.com/reaperes/damn-vulnerable-defi#puppet)
9. [Puppet v2](https://github.com/reaperes/damn-vulnerable-defi#puppet-v2)
10. [Free rider](https://github.com/reaperes/damn-vulnerable-defi#free-rider)
11. Backdoor
12. Climber
13. Safe miners

## Unstoppable
There's a lending pool with a million DVT tokens in balance, offering flash loans for free.
If only there was a way to attack and stop the pool from offering flash loans ...
You start with 100 DVT tokens in balance.

### How to exploit
`flashLoan` 함수 내부에는 아래와 같은 코드가 있습니다. 

UnstoppableLender.sol:40
```
assert(poolBalance == balanceBefore);
```

`poolBalance` 값은 `UnstoppableLender` contract 가 보유하고 있는 DVT 의 balance 를 의미합니다. 또한 
`poolBalance`, `DVT balance of UnstoppableLender` 두 값은 반드시 일치되도록 구성되어 있습니다.
하지만 공격자가 ERC20 의 `transfer` 를 통해 인위적으로 token 을 전송하면 두 값이 불일치 되어, 위의 조건이 어긋나게 되어
더 이상 `flashLoan` 을 실행할 수 없게 됩니다.

실제 공격 하는 코드는 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/unstoppable/unstoppable.challenge.js#L43) 
를 참고해 주세요.

## Naive receiver
There's a lending pool offering quite expensive flash loans of Ether, which has 1000 ETH in balance.
You also see that a user has deployed a contract with 10 ETH in balance, capable of interacting with the lending pool and receiveing flash loans of ETH.
Drain all ETH funds from the user's contract. Doing it in a single transaction is a big plus ;)

### How to exploit
`NaiveReceiverLenderPool` 과 `FlashLoanReceiver` 는 서로 밀접한 관련이 있는 컨트랙트 입니다. 기본적으로 배포자는
`NaiveReceiverLenderPool` 에 자금을 유치해 놓고, `FlashLoanReceiver` 컨트랙트를 이용해서 일부 자금을 빌려 사용 후
다시 일정 수수료와 함께 `NaiveReceiverLenderPool` 에 다시 자금을 반환하는 구조 입니다. 하지만 `FlashLoanReceiver`
가 가지고 있는 취약점으로 인해 `FlashLoanReceiver` ether 자금이 고갈 될 수 있습니다.

`FlashLoanReceiver` 에서 [취약한 부분](https://github.com/reaperes/damn-vulnerable-defi/blob/master/contracts/naive-receiver/FlashLoanReceiver.sol#L21)은 다음과 같습니다.
```
function receiveEther(uint256 fee) public payable {
    require(msg.sender == pool, "Sender must be pool");

    uint256 amountToBeRepaid = msg.value + fee;

    require(address(this).balance >= amountToBeRepaid, "Cannot borrow that much");
    
    _executeActionDuringFlashLoan();
    
    // Return funds to pool
    pool.sendValue(amountToBeRepaid);
}
```
해당 함수는 아무나 호출 할 수 있게 되어 있고, 돈을 빌릴때 파라미터 검증 없이 돈을 빌리게 되어 있습니다.
따라서 이부분을 활용해 공격자가 지속적으로 0 ether 를 빌리도록 강제하면 컨트랙트의 ether 가 고갈 되게 됩니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/naive-receiver/naive-receiver.challenge.js#L33)
를 참고해 주세요.

## Truster
More and more lending pools are offering flash loans. In this case, a new pool has launched that is offering flash loans of DVT tokens for free.
Currently the pool has 1 million DVT tokens in balance. And you have nothing.
But don't worry, you might be able to take them all from the pool. In a single transaction.

### How to exploit
TrusterLenderPool 에는 임의의 data 를 임의의 address 에 call 할 수 있는 취약점 코드가 포함되어 있습니다.
ERC20 의 approve & transferFrom 을 이용하면 flashLoan 함수를 호출하면서 approve 를 실행시켜 놓고,
이후에 transferFrom 을 이용해 contract 에 들어 있는 token 을 탈취할 수 있습니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/naive-receiver/naive-receiver.challenge.js#L32)
를 참고해 주세요.

## Side entrance
A surprisingly simple lending pool allows anyone to deposit ETH, and withdraw it at any point in time.
This very simple lending pool has 1000 ETH in balance already, and is offering free flash loans using the deposited ETH to promote their system.
You must take all ETH from the lending pool.

### How to exploit
LenderPool 은 flashLoan 실행 시 마지막 검증 과정에서 현재 contract 의 balance 가 이전보다 줄지 않았는지만 확인합니다.
하지만 flashLoan 상황에서 실제 반환이 아닌, deposit 을 이용한 반환을 할 경우 attacker 가 돈을 모두 가로챌 수 있습니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/side-entrance/side-entrance.challenge.js#L26)
를 참고해 주세요.

## The rewarder
There's a pool offering rewards in tokens every 5 days for those who deposit their DVT tokens into it.
Alice, Bob, Charlie and David have already deposited some DVT tokens, and have won their rewards!
You don't have any DVT tokens. But in the upcoming round, you must claim most rewards for yourself.
Oh, by the way, rumours say a new pool has just landed on mainnet. Isn't it offering DVT tokens in flash loans?

### How to exploit
RewarderPool 은 기본적으로 스테이킹 한 금액에 비례해서 rewardToken 을 분배 합니다. 하지만 스테이킹을 한 직후에
보상을 분배 하기 때문에, 분배 가능한 시점 직후에 취약점 공격 transaction 을 보내면 스테이킹 한 것과 동일한 지위를 획득하여 
보상을 분배 받을 수 있습니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/the-rewarder/the-rewarder.challenge.js#L68)
를 참고해 주세요.

## Selfie
A new cool lending pool has launched! It's now offering flash loans of DVT tokens.
Wow, and it even includes a really fancy governance mechanism to control it.
What could go wrong, right ?
You start with no DVT tokens in balance, and the pool has 1.5 million. Your objective: take them all.

### How to exploit
Pool 에는 governance 만 실행할 수 있는 drainAllFunds 함수가 있습니다. 그리고 Governance 는 token 발행량의 절반
이상을 가지고 있을 경우 governance action 을 실행할 수 있는 권한을 가지게 됩니다. 또한 해당 권한 체크는 등록할 때만
필요하며, 실제 실행 시점은 필요 없습니다. 이 기능을 엮어서

1. pool 에서 flash loan 을 빌리면서 governance 를 통해 drainAllFunds 를 실행하는 action 등록
2. 실행 대기 최소 기간 이후 governance 에서 action 을 호출해 drainAllFunds 를 실행

순서로 실행하면 pool 이 가지고 있는 모든 DVT 토큰을 가로챌 수 있습니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/selfie/selfie.challenge.js#L33)
를 참고해 주세요.

## Compromised
While poking around a web service of one of the most popular DeFi projects in the space, you get a somewhat strange response from their server. This is a snippet:
```
HTTP/2 200 OK
content-type: text/html
content-language: en
vary: Accept-Encoding
server: cloudflare

4d 48 68 6a 4e 6a 63 34 5a 57 59 78 59 57 45 30 4e 54 5a 6b 59 54 59 31 59 7a 5a 6d 59 7a 55 34 4e 6a 46 6b 4e 44 51 34 4f 54 4a 6a 5a 47 5a 68 59 7a 42 6a 4e 6d 4d 34 59 7a 49 31 4e 6a 42 69 5a 6a 42 6a 4f 57 5a 69 59 32 52 68 5a 54 4a 6d 4e 44 63 7a 4e 57 45 35

4d 48 67 79 4d 44 67 79 4e 44 4a 6a 4e 44 42 68 59 32 52 6d 59 54 6c 6c 5a 44 67 34 4f 57 55 32 4f 44 56 6a 4d 6a 4d 31 4e 44 64 68 59 32 4a 6c 5a 44 6c 69 5a 57 5a 6a 4e 6a 41 7a 4e 7a 46 6c 4f 54 67 33 4e 57 5a 69 59 32 51 33 4d 7a 59 7a 4e 44 42 69 59 6a 51 34
```
A related on-chain exchange is selling (absurdly overpriced) collectibles called "DVNFT", now at 999 ETH each
This price is fetched from an on-chain oracle, and is based on three trusted reporters: 0xA73209FB1a42495120166736362A1DfA9F95A105,0xe92401A4d3af5E446d93D11EEc806b1462b39D15 and 0x81A5D6E50C214044bE44cA0CB057fe119097850c.
Starting with only 0.1 ETH in balance, you must steal all ETH available in the exchange.

### How to exploit
서버에서 받은 hexadecimal 코드를 ascii 로 변환하고, base64 decode 를 해보면 private key 가 나옵니다. 해당 private
key 를 이용해 public address 를 추출하면 trusted source 주소가 나옵니다. 훔친 key 를 활용해 oracle 의 시세를 살때는
저렴하게, 팔때는 비싸게 되파는 형식으로 tx 를 보내면 exchange 에 있는 모든 ether 를 가로챌 수 있습니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/compromised/compromised.challenge.js#L63)
를 참고해 주세요.

## Puppet
There's a huge lending pool borrowing Damn Valuable Tokens (DVTs), where you first need to deposit twice the borrow amount in ETH as collateral. The pool currently has 100000 DVTs in liquidity.
There's a DVT market opened in an Uniswap v1 exchange, currently with 10 ETH and 10 DVT in liquidity.
Starting with 25 ETH and 1000 DVTs in balance, you must steal all tokens from the lending pool.

### How to exploit
PuppetPool 은 oracle 에 있는 가격의 2배를 지불하면 DVT token 을 대여할 수 있게끔 구조가 되어 있습니다.
```
function borrow(uint256 borrowAmount) public payable nonReentrant {
    uint256 depositRequired = calculateDepositRequired(borrowAmount);
    require(msg.value >= depositRequired, "Not depositing enough collateral");
    ...
}

function calculateDepositRequired(uint256 amount) public view returns (uint256) {
    return amount * _computeOraclePrice() * 2 / 10 ** 18;
}
```

Oracle 가격은 uniswap pair 에만 의존 되고 있습니다.
```
function _computeOraclePrice() private view returns (uint256) {
    // calculates the price of the token in wei according to Uniswap pair
    return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
}
```

또한 현재 oracle 의 liquidity 는 10ETH, 10DVT 로 가격 변동에 취약합니다. 이를 활용해

1. swap 을 통해 Oracle 가격 조작
2. 조작된 가격으로 토큰 대여

를 실행하면 pool 에 있는 모든 DVT 토큰을 탈취할 수 있습니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/puppet/puppet.challenge.js#L105)
를 참고해 주세요.

## Puppet V2
The developers of the last lending pool are saying that they've learned the lesson. And just released a new version!
Now they're using a Uniswap v2 exchange as a price oracle, along with the recommended utility libraries. That should be enough.
You start with 20 ETH and 10000 DVT tokens in balance. The new lending pool has a million DVT tokens in balance. You know what to do ;)

### How to exploit
Puppet V2 의 lending pool 도 uniswap v2 의 oracle 을 이용해 borrow 가격을 결정합니다.
바로 이전 문제 puppet 과 동일한 방법으로 oracle 의 가격을 조작하여, pool 에 있는 모든 DVT 토큰을 탈취할 수 있습니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/puppet-v2/puppet-v2.challenge.js#L84)
를 참고해 주세요.

## Free rider
A new marketplace of Damn Valuable NFTs has been released! There's been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH
A buyer has shared with you a secret alpha: the marketplace is vulnerable and all tokens can be taken. Yet the buyer doesn't know how to do it. So it's offering a payout of 45 ETH for whoever is willing to take the NFTs out and send them their way.
You want to build some rep with this buyer, so you've agreed with the plan.
Sadly you only have 0.5 ETH in balance. If only there was a place where you could get free ETH, at least for an instant.

### How to exploit
marketplace 에는 아래와 같은 코드가 있습니다
```
function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
    for (uint256 i = 0; i < tokenIds.length; i++) {
        _buyOne(tokenIds[i]);
    }
}

function _buyOne(uint256 tokenId) private {       
    ...
    require(msg.value >= priceToPay, "Amount paid is not enough");
    ...
}
```
_buyOne(uint256 tokenId) 함수는 `msg.value` 가 `priceToPay` 보다 큰지 비교하는 부분이 있지만, 이는 1개를 구매할
때만 정상적으로 동작하고, 여러개를 살 경우에는 버그가 발생합니다. 예를 들어 15 ETH, 15 ETH 가격의 2 nft 를 구매할 경우
15 ETH 만 전송해도 해당 검증 코드를 통과하게 됩니다. 이를 이용해 marketplace 의 모든 nft 를 15 ETH 만으로 6개를 탈취할
수 있습니다.

하지만, 현재 attacker 는 0.5 ETH 만 들고 있어서 해당 취약점을 공격할 수 없습니다. 이는 uniswap V2 의 Flash loan 을
이용해 15 ETH 를 대여해 marketplace 를 모두 탈취할 수 있습니다.

상세한 취약점 공격하는 부분은 [링크](https://github.com/reaperes/damn-vulnerable-defi/blob/master/test/free-rider/free-rider.challenge.js#L107)
를 참고해 주세요.
