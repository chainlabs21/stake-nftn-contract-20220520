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
	mapping ( address => uint256) public _claimed_amounts ;
	mapping ( address => uint256 ) public _claim_time ;
    mapping ( address => uint256 ) public _balancesums ;
	constructor (string memory name
		, string memory symbol
		, address __reward_token //  , address __vault
	) public { // solhint-disable-previous-line no-empty-blocks 
		_owner = msg.sender ;
		_reward_token = __reward_token;
//    _vault = __vault ;
//		addMinter ( address(this) ) ;
//		for (uint256 i=1; i<=5; i++ ) { mint( address(0x5c7552f154D81a99e2b5678fC5fD7d1a4085d8d7) , i ) ;}
//		for (uint256 i=6; i<=13; i++ ) { mint( address(0xCF529119C86eFF8d139Ce8CFfaF5941DA94bae5b) , i ) ;}
	}
/** 	function onKIP17Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4){
//		return bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"));
//		return bytes4(keccak256("onKIP17Received(operator,from, uint256 tokenId, bytes memory data)"));
    return this.onKIP17Received.selector;
	}*/
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
	function query_claimable_amount ( address _address ) public view returns ( uint ) {
		uint256 heldamount = _balancesums [_address] ; // ; balanceOf ( _address) ;
		if ( heldamount == 0){ return 0; }
		uint256 claimable_amount = 0;
		uint256 claimtime = _claim_time [ _address ] ;
		if ( claimtime > 0 ) { // has claimed before
			for ( uint256 idx = 0; idx < heldamount ; idx ++ ) {
				claimable_amount += _unit_reward_amount * ( block.timestamp - claimtime ) / 3600 / 24 ;
			}
		} else { // 
				claimable_amount += _unit_reward_amount * ( block.timestamp - _deposit_time[ _address] )/ 3600 /24 ;
/** 			for ( uint256 idx = 0; idx < heldamount ; idx++) {
				uint256 tokenid = tokenOfOwnerByIndex( _address , idx );
				claimable_amount += _unit_reward_amount * ( block.timestamp - _deposit_ti me[ _address][ tokenid ]) / 3600 /24 ;
			} */
		}
		return claimable_amount ;
	} //     function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
	event Claim (		address _address , uint256 _amount ) ;
	function claim () public {
		uint256 claimable_amount = query_claimable_amount ( msg.sender ) ; //    _ensure_amount_from_myself_or_vault( _reward_token , _vault, claimable_amount );
		if ( _vault == address(0 )){} // use this' own reserve
		else {
			if ( IERC20( _reward_token ).allowance( _vault, address(this) ) >=claimable_amount ){  // pull upon demand
			   IERC20( _reward_token ).transferFrom ( _vault , address(this ) , claimable_amount );
			} else {}
		}
		IERC20( _reward_token ).transfer( msg.sender , claimable_amount ) ;
		_cumul_claim_count+=1;
		_cumul_claim_amount += claimable_amount ;
		_claim_time [ msg.sender ]  = block.timestamp ;
		_claimed_amounts [ msg.sender ] += claimable_amount;
		emit Claim ( msg.sender , claimable_amount ) ;
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
	function withdraw ( address _erc20 , uint256 _amount , address _to ) public {
  //  _ensure_erc721_token_from_myself_or_vault( _erc721, _vault, _tokenid );
//		KIP17 (_erc721).safeTransferFrom ( address ( this ) , _to , _tokenid );
	//	burn ( _tokenid ) ;
		if (_balancesums [ msg.sender ] >=_amount ){}
		else {revert("ERR() balance not enough"); }
		IERC20 ( _erc20 ).transfer ( _to  , _amount);
		_withdraw_time [ msg.sender ] = block.timestamp ;
		_cumul_withdraw_count+=1;
//		IKIP17 ( _erc721 ).transfer ( _to , _tokenid ) ;
//		emit Withdraw ( _erc721 , _tokenid ) ;
	}
/** 	function withdraw_batch ( address _erc721 , uint256 [] memory _tokenids , address _to ) public {
		uint256 N = _tokenids.length ;
		for ( uint256 i = 0 ; i<N;i++){
			uint256 tokenid = _tokenids[ i ] ;
//      _ensure_erc721_token_from_myself_or_vault( _erc721, _vault, tokenid );
			KIP17 (_erc721).safeTransferFrom ( address ( this ) , _to , tokenid );
			burn ( tokenid ) ;
			_withdraw_time [ msg.sender ] [ tokenid ] = block.timestamp ;
//			_balances [msg.sender][ _tokenids [ i ] ] = 0 ;
//			IKIP17( _erc721 ).transfer ( _to , _tokenids[ i ]) ;
		}
//		emit Withdraw ( _erc721 , _tokenids[ 0 ] ) ;
	}*/
/********* */
	function deposit ( address _erc20 , uint256 _amount ) public {
//		IKIP17 ( _erc721).safeTransferFrom ( msg.sender , address(this) , _tokenid , "0x00") ;		
//		_balancesums [ msg.sender ] += 1; 
	//	_balances [msg.sender][ _tokenid] = 1;
//		mint ( msg.sender , _tokenid ) ;
//function mint(address to, uint256 tokenId)
//    IKIP17 ( _erc721 ).approve ( msg.sender , _tokenid ) ;
// approve (msg.sender , _tokenid );
//		addMinter ( msg.sender ) ;
//		_count_deposited += 1 ;
//    if ( IERC20( _reward_token ).balanceOf( address(this) ) >= _reward_amount ) {
//    	IERC20 (_reward_token).transfer ( msg.sender , _reward_amount ) ;
  //  }
	// else {}
		_deposit_time [ msg.sender ] = block.timestamp ;
    if (_vault == address(0)){}
    else { //      IKIP17 ( _erc721).safeTransferFrom ( address(this) , _vault , _tokenid , "0x00" );
			IERC20 ( _erc20 ).transferFrom ( msg.sender , address ( this ) , _amount ) ;
			_cumul_deposit_count+=1;
    } //		emit Deposit ( _erc721 , _tokenid );
		_balancesums [ msg.sender ] += _amount ;
	}
/** 	function deposit_batch ( address _erc721 , uint256 [] memory _tokenids ) public {
		uint256 N= _tokenids.length;
		for (uint256 i=0; i< N ; i++) {
      uint256 tokenid = _tokenids[ i ] ;
			IKIP17 (_erc721).safeTransferFrom ( msg.sender , address ( this), tokenid , "0x00" ) ;
			mint ( msg.sender , tokenid ) ;
//			_balances [msg.sender][ tokenid ] = 1;
// approve (msg.sender , tokenid );
	//		IKIP17 ( _erc721 ).approve ( msg.sender , tokenid ) ;
			_deposit_time [ msg.sender ][ tokenid ] = block.timestamp ;
      if(_vault == address(0)){}
      else{
        IKIP17 ( _erc721).safeTransferFrom ( address(this) , _vault , tokenid , "0x00" );
      }
		}
//		addMinter ( msg.sender ) ;
//		_count_deposited += N ;
//    if ( IERC20( _reward_token ).balanceOf( address(this) ) >=_tokenids.length * _reward_amount ) {
//    	IERC20 (_reward_token).transfer ( msg.sender , _tokenids.length *  _reward_amount ) ;
//		}
//		else {}
//		_balancesums [ msg.sender ] += N ;
//		emit Deposit ( _erc721 , _tokenids[ 0 ] );
	} */
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
/*  function _ensure_amount_from_myself_or_vault ( address _token , address _vault , uint256 _amount ) internal {
    if ( IERC20( _token ).balanceOf ( address( this) ) >= _amount ){
    } else if ( _vault == address(0) ){ revert("ERR() reserve not enough"); }
    else if ( IERC20( _vault ).balanceOf( address (this) ) >= _amount ){
      IERC20( _token ).transferFrom ( _vault , address(this) , _amount );
    }else {revert("ERR() reserve low");}
  } */
/**  function _ensure_erc721_token_from_myself_or_vault ( address _erc721 , address _vault , uint256 _tokenid ) internal {
    if ( IKIP17(_erc721).ownerOf( _tokenid) == address(this) ){}
    else if ( _vault == address(0)){  revert("ERR() vault does not hold token");}
    else if ( IKIP17(_erc721 ).ownerOf(_tokenid) == _vault ){
      IKIP17( _erc721 ).transferFrom ( _vault , address(this) , _tokenid );
    } else {  revert("ERR() reserve low");
    }
  }*/
/**	function query_claimable_amount_dummy ( address _address ) public view returns ( uint ) {
		return random()%_reward_amount ; 
	} 
	function claim_dummy ( ) public {
		IERC20 ( _reward_token ).transfer ( msg.sender , _reward_amount ) ;
		_claim_time [ msg.sender ]  = block.timestamp ;
	}
	function query_pending_reward () public view returns ( uint ) {
		return random()%_reward_amount ; 
	}
		function query_claimed_reward_dummy () public view returns ( uint ) {
		return random() % _reward_amount ;
	}
	*/