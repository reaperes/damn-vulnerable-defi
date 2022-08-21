# Damn vulnerable defi CTF challenges

1. [Unstoppable](https://github.com/reaperes/damn-vulnerable-defi#unstoppable)
2. [Naive receiver](https://github.com/reaperes/damn-vulnerable-defi#naive-receiver)
3. Truster
4. Side entrance
5. The rewarder
6. Selfie
7. Compromised
8. Puppet
9. Puppet v2
10. Free rider
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
