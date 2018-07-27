# 建立自己的Private Chain并且撰写一个简单的智能合约

## 1.1 Prerequisite

参见https://github.com/ethereum/go-ethereum/wiki/Private-network

## 1.2 Snippets

1. 建立创世区块geth --datadir [datadir_path] init [genesis_profile.json]
2. 创建PrivateChain网络，注意network_id的选择geth --datadir [data_dir_path] --networkid [network_id]
3. 另开一个终端，通过IPC的方式连接上节点geth attach [data_dir_path]/geth.ipc
4. 创建一个账户personal.newAccount()
5. miner.start()
6. miner.stop()
7. 在Remix上编辑智能合约

~~~javascript
pragma solidity ^0.4.17;

contract greeter {
    
    address owner;
    string greeting;
    
    function greeter(string _greeting) public {
        greeting = _greeting;
        owner = msg.sender;
    }
    
    function kill() {
        if (msg.sender == owner) selfdestruct(owner);
    }
    
    function greet() constant returns (string) {
        return greeting;
    }
}
~~~

8. 编译后，在Detail中找到web3的代码

~~~
var _greeting = /* var of type string here */ ;
var greeterContract = web3.eth.contract([{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"greet","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"name":"_greeting","type":"string"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"}]);
var greeter = greeterContract.new(
   _greeting,
   {
     from: web3.eth.accounts[0], 
     data: '0x6060604052341561000f57600080fd5b604051610316380380610316833981016040528080519091019050600181805161003d92916020019061005f565b505060008054600160a060020a03191633600160a060020a03161790556100fa565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106100a057805160ff19168380011785556100cd565b828001600101855582156100cd579182015b828111156100cd5782518255916020019190600101906100b2565b506100d99291506100dd565b5090565b6100f791905b808211156100d957600081556001016100e3565b90565b61020d806101096000396000f300606060405263ffffffff7c010000000000000000000000000000000000000000000000000000000060003504166341c0e1b58114610047578063cfae32171461005c57600080fd5b341561005257600080fd5b61005a6100e6565b005b341561006757600080fd5b61006f610127565b60405160208082528190810183818151815260200191508051906020019080838360005b838110156100ab578082015183820152602001610093565b50505050905090810190601f1680156100d85780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6000543373ffffffffffffffffffffffffffffffffffffffff908116911614156101255760005473ffffffffffffffffffffffffffffffffffffffff16ff5b565b61012f6101cf565b60018054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156101c55780601f1061019a576101008083540402835291602001916101c5565b820191906000526020600020905b8154815290600101906020018083116101a857829003601f168201915b5050505050905090565b602060405190810160405260008152905600a165627a7a72305820640ade17d444cbd25d1b1c32f8a6e25473b58a5f8ed84833db4500dafffd7a7b0029', 
     gas: '4700000'
   }, function (e, contract){
    console.log(e, contract);
    if (typeof contract.address !== 'undefined') {
         console.log('Contract mined! address: ' + contract.address + ' transactionHash: ' + contract.transactionHash);
    }
 })
~~~

9. 注意上述代码其实是三段，在第一段中修改需要的字符串，例如

~~~
var _greeting = "Hello, this is a test"
~~~

第二段代码其实是代码的ABI，在后面需要利用到，也就是说注意第二行的greeterContract

10. 将上述代码在终端2（也就是attach之后的终端）上运行，会发现第三段代码报错，因为没有账号解锁，利用

~~~
personal.unlockAccount(web3.eth.accounts[0])
~~~

解锁账号，然后重新输入第三行代码，得到合约代码的地址0xbd647c6d9a6c02391bab9380e3dc3a6fde4e1000

11. miner.start() miner.stop()将智能合约输入区块链中
12. 利用合约代码的ABI和合约代码地址执行合约代码

~~~
greeterContract.at("0xbd647c6d9a6c02391bab9380e3dc3a6fde4e1000").greet()
~~~

