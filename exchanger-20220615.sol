pragma solidity ^0.8.12;
 interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender
			, address recipient
			, uint256 amount
		) 		external returns (bool);
		function mint ( address _to , uint256 _amount  ) external returns ( bool );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Random {
	function random() public view returns (uint) {
			// sha3 and now have been deprecated
			return uint(keccak256(abi.encodePacked( block.difficulty , block.timestamp )));
			// convert hash to integer
			// players is an array of entrants			
	}
}
contract Exchanger
{
    uint256 public _cumul_exchange_count = 0 ;
    uint256 public _cumul_exchange_amount = 0 ;
    address public _vault ;
    address public _owner ;
    constructor ( ) {
        _owner = msg.sender ;
    }
    function _set_vault ( address __vault ) public {
        require ( __vault != _vault, "ERR() redundant call" );
        _vault = __vault ;
    }
    function exchange ( address _fromtoken 
        , address _totoken 
        , uint256 _exchangerate
        , uint256 _fromamount
        , uint256 _toamount
        , address _to
    ) public {
        if ( IERC20( _fromtoken ).transferFrom ( msg.sender , address(this) , _fromamount ) ) {}
        else {revert("ERR() balance not enough"); }
        if ( _vault == address(0)){
            IERC20( _totoken).transfer ( _to , _toamount ) ;
        } else {
            if ( IERC20( _totoken).transferFrom ( _vault , _to , _toamount  )) {}
            else {revert("ERR() vault balance not enough"); }
        }
        _cumul_exchange_amount += _toamount ;
        _cumul_exchange_count += 1;
    } 
    function withdraw_fund ( address _token , address _to , uint256 _amount ) public {
  	    require (msg.sender == _owner , "ERR() not privileged") ;
        IERC20( _token ).transfer ( _to , _amount );
	    }
    
}
