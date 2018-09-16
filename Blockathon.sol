// Author: p1usj4de

pragma solidity ^0.4.24;

contract GamblingGame {

    enum STATE { INIT, APPROVED, FINISHED }

    struct Game {
        STATE _state;
        uint _funds;
        string _content;
        address _initiator;
        uint _least_participants;
        uint _users_num;
        // Notes: after the game satisfy the least participants, we can 
        // delay some time to wait for more participants
        //uint _delay_time;
        mapping (uint => User) _users;
    }

    struct User {
        address _address;
        string _name;
        uint _games_num;
        mapping (uint => Game) _games;
    }

    uint public _usersNum;
    uint public _gamesNum;
    mapping (uint => User) public _users;
    mapping (uint => Game) public _games;

    function userHasRegistered(address userAddress) public view returns (bool) {
        for (uint index = 0; index != _usersNum; index++) {
            if (_users[index]._address == userAddress) {
                return true;
            }
        }
        return false;
    }

    function gameHasExisted(string gameContent) public view returns (bool) {
        for (uint index = 0; index != _gamesNum; index++) {
            if (bytes(_games[index]._content).length == bytes(gameContent).length && 
            keccak256(_games[index]._content) == keccak256(gameContent)) {
                return true;
            }
        }
        return false;
    }

    // Notes: this function will base on game's initiator and contents 
    // create a hash value to ensure the same game will not be created twice
    function hashGame(Game game) private pure returns (string) {
        return game._content;
    }

    function registerUser(address userAddress, string userName) public returns (bool) {
        require(userHasRegistered(userAddress) == false, "Error: User has registered!");
        
        _users[_usersNum++] = User(userAddress, userName, 0);
        
        if (!userHasRegistered(userAddress)) {revert("Error: User cannot registerd because of unknown reson!");}
    }

    function initGame(uint leastParticipants, string gameContent, uint funds) public returns (bool) {
        require(userHasRegistered(msg.sender), "Error: User should create one game before registered!");
        require(!gameHasExisted(gameContent), "Error: The system has own one same game!");
        
        _games[_gamesNum++] = Game(STATE.INIT, funds, gameContent, msg.sender, leastParticipants, 0);
        
        if (!gameHasExisted(gameContent)) {revert("Error: The game cannot be created, because of unkown reason!");}
    }

    function participantGame(uint gameId, uint fund) public {
        require(userHasRegistered(msg.sender), "Error: User should participant one game before registered!");
        require(gameId < _gamesNum, "Error: Wrong game id!");
        
        Game storage tempG = _games[gameId];
        User storage tempU = findUser(msg.sender);

        tempU._games[tempU._games_num++] = tempG; // add the game's user
        tempG._users[tempG._users_num++] = tempU; // add the user's game
        tempG._funds += fund; // add the game's funds

        // test if the game's requirement has satisfied
        if (tempG._users_num >= tempG._least_participants) {
            tempG._state = STATE.APPROVED;
        }
    }

    // ----------------------------------------------------------------------
    // -- private functions here
    // ----------------------------------------------------------------------
    // Notes: this function will not test the user existed or not
    function findUser(address userAddress) private view returns (User storage result) {
        for (uint index = 0; index != _usersNum; index++) {
            if (_users[index]._address == userAddress) {
                result = _users[index];
            }
        }
    }
}