
//by jnbez

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import"@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Privatesale is Ownable {
//@ chainlink <price feeds> ;
AggregatorV3Interface internal ETH_USD_priceFeed;
AggregatorV3Interface internal  Matic_USD_priceFeed;





uint256 Minimum_cap ;
uint256 maxinum_cap ;
uint public saleStart = block.timestamp;  
uint public saleEnd = block.timestamp + 31536000; //after about 6 month ;   
uint256 public raisedAmount;
uint8 pause=0 ;

IERC20 public erc20Contract;
IERC20 public usdtContract;
IERC20 public maticContrat ;

mapping (address => uint256) invester_id ;
mapping (address => uint256) invest_balance ;

address payable withdraw_wallet ;
address[] public invsters ;

constructor (IERC20 _erc20_contract_address,IERC20 usdt_contract_address, IERC20 _maticContrat ,
 uint256 _Minimum_cap ,uint256 _maxinum_cap,address payable _withdraw_wallet )
  { 
        Minimum_cap=_Minimum_cap ;
         maxinum_cap = _maxinum_cap ;
        //for Mumbai network 
         ETH_USD_priceFeed = AggregatorV3Interface( 
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
        Matic_USD_priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        // 
        erc20Contract = _erc20_contract_address;
        usdtContract= usdt_contract_address ;
        maticContrat = _maticContrat;

    //The fundraised (with eth, usdt and matic) must be transferred to a specific wallet.
        withdraw_wallet =_withdraw_wallet ;

}
// the owner can stop SALE at any time
modifier Not_pause() {
     require(pause== 0, "Private sale is stoping , maybe it is paused by owner ");
        _;
    }

//he maximum duration of a private sale is 6 months.
modifier still_sale() {
     require(block.timestamp<=saleEnd, "Private sale is ending  , maybe it is ended ");
        _;
    }

//
//@later : for professional code : 3 above in another smartcontract .

//CONVERT USDT TO WEI ,to let contract accpect Usdt after 
function Usdt_wei (uint usdt_amount) public view returns(uint256){
        (,int price,,,) =ETH_USD_priceFeed.latestRoundData();
        uint adjust_price = uint(price) * 1e10;
        uint usdt =  usdt_amount * 1e18;
        uint wei_amount = ( usdt * 1e18) / adjust_price;
        return wei_amount ;
        //@Later: float point issu : for professional code need to review ; wrong :2% ;

    }

// get 0.16$ on wei based on live Eth/usdt price .
    function get_price_in_wei() public view   returns(uint256){
     uint256 res = Usdt_wei(16);
     return res/100 ;
     //@Later: float point issu : for professional code need to review ;

    }

//CONVERT USDT TO matic ,to let contract accpect matic after 

    function MATIC_wei (uint matic_amount) public view returns(uint256){
        (,int price,,,) =Matic_USD_priceFeed.latestRoundData();

        uint256 price_ = uint256(price) * 1e10 ;
        uint256 _matic_account =  matic_amount ;
        uint256 _usdt_amount= (price_*_matic_account)/1e18 ;
        return Usdt_wei (_usdt_amount) ;
     //@Later: float point issu : for professional code need to review ;

    }




function _pause() public payable  onlyOwner {
    pause =1 ;
}
function Un_pause() public payable onlyOwner{
    pause = 0;
}

event add_invest(address _invest_address) ;

//let owner allow private user to invest (by address) by any time ,if the sale is still running  ;
function Add_investers (address _invest_address) public payable still_sale onlyOwner{
    invester_id[_invest_address] = invsters.length+1;
    invsters.push(_invest_address);
    emit  add_invest( _invest_address) ;

}
event LOG_Invest_By_ETH(address invetser,uint256 _eth , uint256 _token_get);

function Invest_By_ETH()  payable public Not_pause still_sale returns (bool) {
      // check if the caller of function allowed to invest .
        require( invester_id [msg.sender]>0);

        require(msg.value >= Minimum_cap && msg.value <= maxinum_cap );
        require(invest_balance[msg.sender]+msg.value < maxinum_cap,"you get the max cap");
         //The goal of this private sale is to reach 15 million dollars
        require(raisedAmount<Usdt_wei(15000000),"sale end ,we do it ");
        raisedAmount += msg.value ;
        uint256 price =get_price_in_wei();
        uint256 INA_Amount = msg.value / price ;
        invest_balance[msg.sender]+= INA_Amount ;
        
         erc20Contract.transferFrom(address(this), msg.sender, INA_Amount);
        // balance[this] -= tokens;
        // deposit.transfer(msg.value)
         emit LOG_Invest_By_ETH(msg.sender, msg.value, INA_Amount);

        return true;
    }

//
// // for another crypto paytments :
    //they have to first go to the USDT contract and call approve((this) privatesale 's smart contract address, amount to spend) 
    //and then call the function .
    //OR doing by javascript or frontend .

//
event LOG_Invest_By_Matic(address invetser,uint256 _matic , uint256 _token_get);

function Invest_By_matic(address inverster ,uint256 _amount)   external payable   Not_pause still_sale returns (bool) {
        //convert sended amount in wei based on live price .
        uint256 wei_amount = MATIC_wei(_amount) ;
        uint256 matictbalance = maticContrat.balanceOf(address(inverster));
        
        // check if the caller of function allowed to invest .
        require( invester_id [inverster]>0);
        //Minimum cap and maximum cap should be considered
        require( wei_amount>= Minimum_cap && wei_amount <= maxinum_cap );
        require(matictbalance>_amount,"no enough usdt");

        // Don't let invester to overrun the maxinum cap
        require(invest_balance[inverster] + wei_amount  < maxinum_cap,"you get the max cap");
       //check if the payement done ;
        require(maticContrat.transferFrom(inverster, address (this),  _amount)) ;
        //The goal of this private sale is to reach 15 million dollars
        require(raisedAmount<Usdt_wei(15000000),"sale end ,we do it ");

        raisedAmount += msg.value ;
        //get amount of INA must send to invest based on live price 
        uint256 price =get_price_in_wei();
        uint256 INA_Amount = wei_amount / price ;

        invest_balance[inverster]+= INA_Amount ;
        erc20Contract.transferFrom(address(this),inverster, INA_Amount);
 
     emit LOG_Invest_By_Matic(inverster, _amount, INA_Amount);
        return true;
    }
    

event LOG_Invest_By_Usdt(address invetser,uint256 _usdt , uint256 _token_get);

function Invest_By_usdt(address inverster ,uint256 _amount)   external payable   Not_pause still_sale returns (bool) {
        //convert sended amount in wei based on live price .

         uint256 wei_amount = Usdt_wei(_amount) ;
         uint256 usdtbalance = usdtContract.balanceOf(address(inverster));


        // check if the caller of function allowed to invest .
        require( invester_id [inverster]>0);

        //Minimum cap and maximum cap should be considered
        require( wei_amount>= Minimum_cap && wei_amount <= maxinum_cap );
        require(usdtbalance>_amount,"no enough usdt");
        // Don't let invester to overrun the maxinum cap
        require(invest_balance[inverster] + wei_amount  < maxinum_cap,"you get the max cap");
       //check if the payement done ;
        require(usdtContract.transferFrom(inverster, address (this),  _amount)) ;

        require(raisedAmount<Usdt_wei(15000000),"sale end ,we do it ");
        raisedAmount += msg.value ;
        uint256 price =get_price_in_wei();
        uint256 INA_Amount = wei_amount / price ;
        invest_balance[inverster]+= INA_Amount ;
        erc20Contract.transferFrom(address(this),inverster, INA_Amount);

     emit LOG_Invest_By_Usdt(inverster, _amount, INA_Amount);

        return true;
    }

//two diff method 
//@later 
event Log_withdraw_eth(uint256 amount) ;
event Log_withdraw_usdt(uint256 amount) ;
event Log_withdraw_matic(uint256 amount) ;

    function withdraw() payable public onlyOwner returns(bool){
      emit Log_withdraw_eth(address(this).balance);

        (bool os, ) = withdraw_wallet.call{value: address(this).balance}("");
        require(os,"send to wallet failed");
        return  true ;
    }
    function withdraw_usdt() external onlyOwner {
    emit Log_withdraw_usdt( usdtContract.balanceOf(address(this))) ;

    usdtContract.transfer(withdraw_wallet,usdtContract.balanceOf(address(this)));

        }
    function withdraw_matic() external onlyOwner {
    emit Log_withdraw_matic( maticContrat.balanceOf(address(this))) ;
    maticContrat.transfer(withdraw_wallet,maticContrat.balanceOf(address(this)));
        

    }

}