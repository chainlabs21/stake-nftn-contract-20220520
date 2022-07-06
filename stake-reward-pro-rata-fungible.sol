pragma solidity ^0.5.6;
// import "./IKIP17.sol";
// import "./KIP17.sol";
// import "./KIP17Enumerable.sol";
// import "./KIP17Metadata.sol";
// import "./KIP17Mintable.sol";
// import "./KIP17Burnable.sol";
// import "./IKIP17Receiver.sol";
/**
 * @title Full KIP-17 Token
 * This implementation includes all the required and some optional functionality of the KIP-17 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom ( address sender
		, address recipient
		, uint256 amount
	) 		external returns ( bool );
	function mint ( address _to , uint256 _amount  ) external returns ( bool );
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Random {
	function random() public view returns (uint) {			// sha3 and now have been deprecated
		return uint(keccak256(abi.encodePacked( block.difficulty 
			, block.timestamp )));			// convert hash to integer			// players is an array of entrants			
	}
}
contract Stake_and_reward is Random
	// , KIP17Enumerable
	// , KIP17Metadata
	// , KIP17Mintable
	// , KIP17Burnable , 
	// , IKIP17Receiver
{	address public _reward_token ;
	uint256 public _reward_amount = 1 * 10**18 ;
	address public _owner ;
  	address public _vault ;
	uint256 public _cumul_deposit_count = 0;
	uint256 public _cumul_withdraw_count = 0;
	uint256 public _cumul_claim_count = 0;

	uint256 public _cumul_claim_amount = 0;
	uint256 public _unit_reward_amount = 374 * 10**15 ; // =0.263263
	mapping ( address => uint256 ) public _deposit_time ; // user => token id => timestamp
	mapping ( address => uint256 ) public _withdraw_time ; //
	mapping ( address => uint256 ) public _claim_time ;
	mapping ( address => uint256 ) public _last_balance_change_time ;
    mapping ( address => uint256 ) public _balancesums ;
	mapping ( address => uint256 ) public _claimable_amount ;
	mapping ( address => uint256) public _claimed_amounts ;

	uint256 public _contract_deploy_time ;
	constructor (string memory name
		, string memory symbol
		, address __reward_token //  , address __vault
	) public { // solhint-disable-previous-line no-empty-blocks 
		_owner = msg.sender ;
		_reward_token = __reward_token;
		_contract_deploy_time = block.timestamp ;
	}
  modifier onlyowner ( address _address ) {
    require( _address == _owner , "ERR() not privileged");
    _;
  }
  function set_vault ( address _address ) public onlyowner( msg.sender ) {
    require( _address != _vault , "ERR() redundant call");
    _vault = _address ;
  }
	function set_unit_reward_amount (uint256 _amount ) public {
  	require ( msg.sender == _owner , "ERR() not privileged") ;
		require ( _amount != _unit_reward_amount , "ERR() redundant call" );
		_unit_reward_amount = _amount ;
	}
	function query_claimed_reward () public view returns ( uint ) {
		return _cumul_claim_amount ;
	}
	function set_reward_token ( address _address ) public {
  	require ( msg.sender == _owner , "ERR() not privileged") ;
		require ( _address != _reward_token , "ERR() redundant call" );
    _reward_token = _address ;
  }
/********* */
	event Claim (		address _address , uint256 _amount ) ;
	function query_claimable_amount ( address _address ) public view returns ( uint ) {
		uint256 lastchangetime ;
		if ( ( lastchangetime = _last_balance_change_time [ _address ] ) >0 ) {
			return _claimable_amount [ _address ] + ( block.timestamp - lastchangetime ) * _balancesums [ _address ] * _unit_reward_amount / 3600 / 24 ;
		} else { return 0 ; }
/**		uint256 heldamount = _balancesums [_address] ;
		if ( heldamount == 0){ return 0; }
		uint256 claimable_amount = 0;
		uint256 claimtime = _claim_time [ _address ] ;
		if ( claimtime > 0 ) { // has claimed before
			for ( uint256 idx = 0; idx < heldamount ; idx ++ ) {
				claimable_amount += _unit_reward_amount * ( block.timestamp - claimtime ) / 3600 / 24 ;
			}
		} else { // 
				claimable_amount += _unit_reward_amount * ( block.timestamp - _deposit_time[ _address] )/ 3600 /24 ;
		}
		return claimable_amount ; */
	} //
	function claim () public {
		uint256 claimable_amount = query_claimable_amount ( msg.sender ) ; //    _ensure_amount_from_myself_or_vault( _reward_token , _vault, claimable_amount );
		if ( _vault == address(0 )){} // use this' own reserve
		else {
			if ( IERC20( _reward_token ).allowance( _vault, address(this) ) >=claimable_amount ){  // pull upon demand
			   IERC20( _reward_token ).transferFrom ( _vault , address(this ) , claimable_amount );
			} else {}
		}
		IERC20( _reward_token ).transfer( msg.sender , claimable_amount ) ;
		_claim_time [ msg.sender ]  = block.timestamp ;
		_last_balance_change_time [ msg.sender ]  = block.timestamp ;
		_claimable_amount[ msg.sender ] = 0 ;
		_claimed_amounts [ msg.sender ] += claimable_amount;
		_cumul_claim_count+=1;
		_cumul_claim_amount += claimable_amount ;
		emit Claim ( msg.sender , claimable_amount ) ;
	}
	function withdraw ( address _erc20 , uint256 _amount , address _to ) public {
		if (_balancesums [ msg.sender ] >=_amount ){}
		else {revert("ERR() balance not enough"); }
		IERC20 ( _erc20 ).transfer ( _to  , _amount);

		uint256 lastchangetime ; // = _contract_deploy_time ;
		if ( ( lastchangetime = _last_balance_change_time[ msg.sender ] ) > 0 ){
			_claimable_amount [ msg.sender ] += ( block.timestamp - lastchangetime ) * _balancesums [ msg.sender ] * _unit_reward_amount / 3600 / 24 ;
		}
		else { revert( "ERR() inconsistent state");
			//		_claimable_amount [ msg.sender ]  = 0;
		} 
		_balancesums [ msg.sender ] -= _amount ;
		_withdraw_time [ msg.sender ] = block.timestamp ;
		_last_balance_change_time [ msg.sender ] = block.timestamp ;
		_cumul_withdraw_count+=1;
	}

	function deposit ( address _erc20 , uint256 _amount ) public {
		_deposit_time [ msg.sender ] = block.timestamp ;
	    if (_vault == address(0)){}
    	else { //      IKIP17 ( _erc721).safeTransferFrom ( address(this) , _vault , _tokenid , "0x00" );
		IERC20 ( _erc20 ).transferFrom ( msg.sender , address ( this ) , _amount ) ;
		uint256 lastchangetime = _contract_deploy_time ;
		if( (lastchangetime = _last_balance_change_time[ msg.sender ] )  > 0 ){
			_claimable_amount [ msg.sender ] += ( block.timestamp - lastchangetime ) * _balancesums [ msg.sender ] * _unit_reward_amount  / 3600 / 24 ;
		} 
		else { _claimable_amount [ msg.sender ] = 0 ;	
		}
		_balancesums [ msg.sender ] += _amount ;
		_deposit_time [ msg.sender ] = block.timestamp ; // user => token id => timestamp
	 	_last_balance_change_time [ msg.sender ] = block.timestamp ;
		_cumul_deposit_count+=1;
    } //		emit Deposit ( _erc721 , _tokenid );
}
  function mybalance ( address _token ) public view returns ( uint256 ){ 
		return IERC20( _token ).balanceOf ( address ( this ) );
  }
  function allowance ( address _token , address _holder ) public view returns (uint256) {
	  return IERC20 ( _token).allowance ( _holder , address(this ));
  }
	function withdraw_fund ( address _token , address _to , uint256 _amount ) public {
  	require (msg.sender == _owner , "ERR() not privileged") ;
    IERC20( _token ).transfer ( _to , _amount );
	}
}
