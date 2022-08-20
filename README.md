# Damn vulnerable defi CTF challenges

1. [Unstoppable](https://github.com/reaperes/damn-vulnerable-defi#unstoppable)
2. Naive receiver
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
