pragma solidity ^0.8.10;

//1. Have a contract accept funds from a user and store how much the user gave to the contract 
//To do this have a mapping of balances and a function that can return a balance for a user

//KNOWN ISSUES: someone other than the user can withdraw the user's funds for them(so no major harm, but trolling is a possibility here)
// users have to put their amount in the format with a bunch of zeros (need to multiply what they put in amount by 10^x so they dont have to do that)
contract Step3 {

    
    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) balances;
    
    //we will store the fees the contract collects into balances[owner]
    address payable owner; 
    
    //this is the structure where we hold the details for each "bet"
    struct Bet {
        uint id; //to differentiate from each bet
        uint winCondition; //to know how to determine the winner when called
        mapping(address => uint256) side0; //we store every address that bets on side0 of the bet, with how much they bet
        uint totalSide0;
        mapping(address => uint256) side1; //same as side0 but the other side of the bet
        uint totalSide1;
        mapping(uint => address) betters; //store the betters for both sides
        uint totalBetters;//store the amount of betters for both sides
    }
    
    //for step3 we assume we only have 1 bet
    uint numBets; //number of bets in the contract
    mapping(uint => Bet) public bets;
    
    //create a bet 
    function createBet(uint winCondition) public {
        Bet storage bet = bets[numBets++];
        bet.winCondition = winCondition;
        bet.id = numBets;
    }
    
    // The owner is whoever created the contract
    constructor() {
        owner = payable(msg.sender);
        createBet(4); //create the bet in constructor for easing testing, this bet will have id = 1 
    }
    
    //the receive function is a special solidity built-in function that runs whenever funds are Received
    //this is where we store the user address and their funds into the balances[]
    //note: this only reacts to when it receives Ether/ the main chain token(?)
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
    
    //this reads from the balances[] and returns how much a user has
    function balanceOf(address account) external view returns (uint256) {
        
        return balances[account];
         
    }
    
    //this function withdraws funds for a single user 
    //source: https://docs.soliditylang.org/en/v0.6.2/common-patterns.html#withdrawal-pattern
    //as of now, user has to put the amount with the huge amount of zeros, should change this?
    function withdraw(address payable account, uint256 amount) external {  //TODO: I REMOVED PAYABLE HERE (after external), I DONT THINK ITS NEEDED?
        uint accountBalance = balances[account];
        
        //check if user has enough funds to withdraw x amount
        require(accountBalance >= amount);
        
        //subtract amount to withdraw from accountBalance
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        balances[account] = accountBalance - amount;
        
        //withdraw the amount to the account/user
        account.transfer(amount);
    }
    
    //this function will include the functionality for a user to make a bet on a side of a preexisting bet created, i.e. "Will it rain on Friday"
    //only the owner of an account will be able to call this function/ "represent" itself
                        //uint bet,
    function UserMakeBet(uint bet, uint sideOfBet, uint amount) external {
        uint accountBalance = balances[msg.sender];
        
        //check if user has enough funds to bet x amount
        require(accountBalance >= amount);
        
        balances[msg.sender] = accountBalance - amount;
         
        if(sideOfBet == 0){
            bets[bet].side0[msg.sender] += amount;
            bets[bet].totalSide0 += amount;
        }
        else{
            bets[bet].side1[msg.sender] += amount;
            bets[bet].totalSide1 += amount;
        }
        
        uint temp = bets[bet].totalBetters + 1;
        bets[bet].totalBetters = temp;
        bets[bet].betters[temp] = msg.sender;
        
    }
    
    //this function calls DetermineWinner() to determines the winner of a bet, and then splits the pool accordingly, recording the winnings in the balances mapping
    function EndBet(uint bet) external {
        uint result = DetermineWinner(/*bet*/);
        uint totalBetters = bets[bet].totalBetters;
        if(result == 1){
            //pay out side1/true
            //iterate through every single user who made a bet in this bet
            for(uint i = 0; i < totalBetters; i++){
                //get a user address from the array that stores all addresses that made a bet for this bet
                address user = bets[bet].betters[i];
                
                //check if that user has a bet over zero for this side, if so give their bet back(since they won), then give their portion of the winnings
                //NOTE: for part 3 this is just the entire other side
                if(bets[bet].side1[user] > 0){
                    uint temp = bets[bet].side1[user];
                    bets[bet].side1[user] = 0;
                    balances[user] += temp;
                    balances[user] += bets[bet].totalSide0;
                    bets[bet].totalSide0 = 0;
                }
                //no need to iterate over the losers since they lost, they get nothing back (unless they bet a large amount more than totalSide1, but we ignore this for part3(?))
            }
        }
        else if(result == 0){
            //pay out side2/false
            for(uint i = 0; i < totalBetters; i++){
                //get a user address from the array that stores all addresses that made a bet for this bet
                address user = bets[bet].betters[i];

                if(bets[bet].side0[user] > 0){
                    uint temp = bets[bet].side0[user];
                    bets[bet].side0[user] = 0;
                    balances[user] += temp;
                    balances[user] += bets[bet].totalSide1;
                    bets[bet].totalSide1 = 0;
                }
                //no need to iterate over the losers since they lost, they get nothing back (unless they bet a large amount more than totalSide1, but we ignore this for part3(?))
            }
        }
    }
    
    //this function determines the winner of a bet
    function DetermineWinner(/*uint bet*/) pure internal returns (uint) {

        uint result = 2+2;
        if(result == 4){
            return 1;
        }
        return 0;
    }
}