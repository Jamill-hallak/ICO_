

//by jnbez


pragma solidity >=0.7.0 <0.9.0;
import"@openzeppelin/contracts/access/Ownable.sol";
import"@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import"@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract INA is ERC20,Pausable,Ownable {
    constructor() ERC20("INIAN", "INA") {
        _mint(msg.sender,1000);
    }



    //It should be possible for the owner to lock the tokens of a wallet 
  bool public canPause = true;

    function pause() onlyOwner  public {
        _pause();
    }
    function unpause() onlyOwner  public {
        _unpause();
    }

    function _beforeTokenTransfer(address from , address to , uint256 amount) internal  whenNotPaused override  {
    super._beforeTokenTransfer(from,to,amount);
    }
}



