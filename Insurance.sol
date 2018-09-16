// A basic learning-by-doing insurance contract in Solidity
// Author Davide "dada" Carboni
// Reconstructed by p1usj4de
// Licensed under MIT

pragma solidity ^0.4.24;
contract Insurance {

    // premium is what you pay to subscribe the policy
    //uint public premium;

    // oracle is the 3rd party in charge of stating if a claim is legit
    address public oracle;

    // protection is the financial protection provided by the contract
    //uint public protection;

    // insurer is the one who locks his money to fund the protection
    address public insurer;

    // subscriber is who wants the insurance protection
    //address public subscriber;

    address public bank;
    
    struct UserInsurance{
        uint state;
        uint premium;
        uint protection;
        uint duration;
    }
    
    struct User{
        address userAddress;
        
        string username;
        // address oracle;
        // uint premium;
        // uint prot;
        // uint duration;
        // uint state;
        uint numInsurances;
        mapping(uint => UserInsurance) insurances;
    }
    
    uint public numUsers;
    uint public numInsurances;
    mapping(uint => User) public users;
    mapping (address => uint) public balances;
    
    // create one new user
    function newUser(address userAddress, string username) public returns (uint userID) {
        userID = numUsers++; 
        users[userID] = User(userAddress, username, 0);
        emit newUserCreated(msg.sender, numUsers);
        return userID;
    }

    function newInsurance(uint userID, uint premium, uint prot, uint duration) public payable {
        User storage u = users[userID];
        u.insurances[u.numInsurances++] = UserInsurance(0, premium, prot, duration);
        emit NewInsuranced(msg.sender, u.numInsurances);
    }
    
    function getUser(uint userID) public view returns(address, string, uint)
    {
        User storage u = users[userID];
        return (u.userAddress, u.username, u.numInsurances);
    }

    function getInsurance(uint userID) public view returns(uint, uint, uint, uint)
    {
        User storage u = users[userID];
        UserInsurance storage temp = u.insurances[numInsurances];
        return (temp.state, temp.premium, temp.protection, temp.duration);
    }
    
    function getNumUsers() public view returns (uint) {
        return numUsers;
    }

    function getNumInsurances() public view returns(uint) {
        return  numInsurances;
    }

    // bank send money to user
    function sendMoney(address receiver, uint amount) public payable {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit SentMoney(msg.sender, receiver, amount);
    }

    // bank create money
    function mint(address receiver, uint amount) public {
        if (msg.sender != bank) return;
        balances[receiver] += amount;
        emit Minted(msg.sender, receiver, amount);
    }
    
    function setOracle(address orac) public returns(address) {
        oracle = orac;
        emit SetOracled(msg.sender, orac);
        return oracle;
    }
    
    // contractCreator is who deploys the contract for profit
    address public contractCreator;

    // the contract goes through many states
    //uint public state;
    uint CREATED = 0;
    uint VALID = 1;
    uint SUBSCRIBED = 2;
    uint ACTIVE = 3;
    uint CLAIMED = 4;
    uint EXPIRED = 5;
    uint PAID = 6;
    uint REJECTED = 7;

    // let's assign a fixed profit to who created the contract
    uint constant profit = 200 finney;

    // uration, a contract cannot last for ever
    //uint duration;

    // expireTime is when the contract expires
    uint expireTime;

    event Inited(uint _state);
    event subscribed(address _from, uint _state);
    event backed(address _from , uint _state);
    event claimed(address _from, uint _state);
    event oracleDeclareClaimed(address _from , uint _state);
    event newUserCreated(address _from, uint _numUsers);
    event SentMoney(address _from, address _to, uint _amount);
    event Minted(address _from, address _to, uint _amount);
    event SetOracled(address _from, address _to);
    event NewInsuranced(address _from, uint _numInsurances);

    constructor() public {
        // this function use no args because of Truffle limitation
        contractCreator = msg.sender;
        bank = msg.sender;
        //state = CREATED;
    }

    function init(uint userID, uint numInsurances) public {
        User storage u = users[userID];
        UserInsurance storage ui = u.insurances[numInsurances];
        if (ui.state!=CREATED) revert();
        //u.oracle = anOracle;
        //u.premium = aPremium * 1 ether;
        ui.premium = ui.premium * 1 ether;
        //u.prot = prot * 1 ether;
        ui.protection = ui.protection * 1 ether;
        //u.duration = ttl;

        bool valid;
        // let's check all the var are set
        valid = ui.premium != 0 && ui.protection != 0 && ui.duration != 0;
        if (!valid) revert();
        ui.state = VALID;
        emit Inited(ui.state);
    }

    function subscribe(uint userID, uint numInsurances) public payable {
        User storage u = users[userID];
        UserInsurance storage ui = u.insurances[numInsurances];
        // is in the proper state?
        if (ui.state != VALID) revert();

        // can't be both subscriber and oracle
        if (msg.sender == oracle) revert();

        // must pay the exact sum
        if (balances[u.userAddress]==ui.premium) {
            //users=msg.sender;
            ui.state = SUBSCRIBED;

            // the contract creator grabs his money
            //if (!contractCreator.send(profit)) throw;
            emit subscribed(msg.sender, ui.state);
        }
        else revert();
    }

    function back(uint userID, uint numInsurances) public payable {
        User u = users[userID];
        UserInsurance ui = u.insurances[numInsurances];
        
        // check proper state
        if (ui.state != SUBSCRIBED) revert();

        // can't be both backer and oracle
        if (msg.sender == oracle) revert();

        // must lock the exact sum for protection
        if (balances[msg.sender] > ui.protection){
            insurer = msg.sender;
            ui.state = ACTIVE;
            // insurer gets his net gain
            //if (!insurer.send(u.premium - profit)) throw; // this prevents re-entrant code
            sendMoney(insurer, ui.premium);
            expireTime = now + ui.duration;
            emit backed(msg.sender, ui.state);
        }
        else revert();
    }

    function claim(uint userID, uint numInsurances) public payable {
        User storage u = users[userID];
        UserInsurance storage ui = u.insurances[numInsurances];

        // if expired unlock sum to insurer and destroy contract
        if (now > expireTime) {
            ui.state = EXPIRED;
            //if (!insurer.send(u.prot))throw;
            //selfdestruct(contractCreator);
            sendMoney(insurer, ui.protection);
            emit claimed(msg.sender, ui.state);
        }

        // check if state is ACTIVE
        if (ui.state != ACTIVE) revert();

        // are you the subscriber?
        //if (msg.sender != u.userAddress)throw;

        // ok, claim registered
        ui.state = CLAIMED;
        emit claimed(msg.sender, ui.state);
    }

    function oracleDeclareClaim (bool isTrue, uint userID, uint numInsurances) public payable {
        User storage u = users[userID];
        UserInsurance storage ui = u.insurances[numInsurances];

        // is claimed?
        if (ui.state != CLAIMED) revert();

        // are you the oracle?
        if (msg.sender != oracle) revert();

        // if claim is legit then send money to subscriber
        if (isTrue){
            ui.state = PAID;
            //if (!u.userAddress.send(u.prot))throw;
            sendMoney(u.userAddress, ui.protection);

        } else {
            ui.state = REJECTED;
            //if (!insurer.send(u.prot))throw;
            sendMoney(insurer, ui.protection);
            emit oracleDeclareClaimed(msg.sender, ui.state);

        }

        // in any case destroy the contract and change is back to creator
        //selfdestruct(contractCreator);
    }

}