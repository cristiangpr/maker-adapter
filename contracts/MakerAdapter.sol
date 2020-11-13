// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import { ConditionalTokens } from "./ConditionalTokens.sol";
import { SafeMath } from "./SafeMath.sol";



///@dev interface to read price oracles
interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}
//kovan ConditionalTokens Address 0xf09F9DD23147E5B4139545Bc9ECf282922ec0a1D
//kovan address 0xAdf49005A69AA892572C7d27b6Dc8C0409cc0E3d
contract MakerAdapter {
     using SafeMath for uint256;
     ConditionalTokens public immutable cTokens;
      
      
    /// Mapping key is a questionId. Value is struct containing market values
    mapping(bytes32 => Market) public markets;
     struct  Market {
        address makerPriceFeed;
        uint resolutionTime;
        uint targetValue;
        uint variation;
    }
    

    /// @dev Emitted upon the successful reporting of whether the actual value has exceeded target to the conditional tokens contract.
 
    event ResolutionSuccessful(bytes32 questionId, uint resolutionTime, uint currentTime, uint value, uint[] result);
    
    ///@dev Emitted upon market preparation
  
    event MarketPrepared(bytes32 questionId, uint resolutionTime, uint targetValue, uint variation);
    
   
    
    /// @param _cTokens address of conditional tokens contract to be used
    constructor (ConditionalTokens _cTokens) public {
        cTokens = _cTokens;
    
       
    }
 
    ///@dev Function defines values to be used for market resolution.
    ///@param questionId  bytes32 identifier for the question to be resolved
    ///@param makerPriceFeed address of token price oracle.
    /* Available Feeds
       BALUSD = 0x0C472661dde5B08BEee6a7F8266720ea445830a3
       BATUSD = 0xAb7366b12C982ca2DE162F35571b4d21E38a16FB
       BTCUSD = 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f
       COMPUSD = 0x18746A1CED49Ff06432400b8EdDcf77876EcA6f8
       ETHBTC = 0xF60df9B138A00Ae8DBD07F55fd2305CC791e68cc
       ETHUSD = 0x0E30F0FC91FDbc4594b1e2E5d64E6F1f94cAB23D
       KNCUSD = 0x4C511ae3FFD63c0DE35D4A138Ff2b584FF450466
       LINKUSD = 0x7cb395DF9f1534cF528470e2F1AE2D1867d6253f
       LRCUSD = 0x2aab6aDb9d202e411D2B29a6be1da80F648230f2
       PAXGUSD = 0xE2E348d6f48E51d194f401bad2840ef164d278e2 (activates soon)
       USDTUSD = 0x074EcAe0CD5c37f59D9b91E2994407418aCe05B7
       YFIUSD = 0x67E681d202cf86287Bb088902B89CC66F1A075D4
       ZRXUSD = 0x1A6b4f516d61c73f568ff0Da15891e670eBc1afb*/
    ///@param resolutionTime timestamp of start of valid market resolution window
    ///@param targetValue predicted token price
    ///@param variation  To define a binary market set to 0. To define a scalar market set to desired plus and minus range. Bounds are equal to targetValue +- variation.
  function prepareMarket(bytes32 questionId,  address makerPriceFeed, uint resolutionTime, uint targetValue, uint variation)  external {
      require(resolutionTime >= block.timestamp,  "Please submit a resolution time in the future");
      cTokens.prepareCondition(address(this), questionId, 2);
      markets[questionId].makerPriceFeed = makerPriceFeed;
      markets[questionId].resolutionTime = resolutionTime;
      markets[questionId].targetValue = targetValue;
      markets[questionId].variation = variation;
      
      
      
       emit MarketPrepared(questionId, resolutionTime, targetValue, variation);
  }
   ///@dev reads the price of the token
   ///@param makerPriceFeed address of relevant Maker DAO price feed. Defined at market preparation. 
   
  function getPrice(address makerPriceFeed) internal view returns (uint) {
    
       return uint(IMakerPriceFeed(makerPriceFeed).read());
    
  }
    ///@dev resolves market by getting price from feed, comparing to target value and calling Conditional Tokens reportPayouts function with an array of uints representing payout numerators.
    ///@param questionId used in market preparation
  
    function resolveMarket(bytes32 questionId) external {
      require(markets[questionId].resolutionTime <= block.timestamp, "resolution window has not begun");
     
      
        ///@param value oracle's response
        uint value = getPrice(markets[questionId].makerPriceFeed);
        uint lowerBound = markets[questionId].targetValue.sub(markets[questionId].variation);
        uint upperBound =  markets[questionId].targetValue.add(markets[questionId].variation);
        uint hundred = 100;
        uint[] memory result = new uint[](2);
        /// if value is lower than lower bound pays 100% to short position and 0 to long.
        if (value < lowerBound) {
              result[0] = 1;
              result[1] = 0;
          cTokens.reportPayouts(questionId, result);
        } 
        /// if value is higher than higher bound pays 100% to long position and 0 to short.
        else if (value > upperBound) {
             result[0] = 0;
             result[1] = 1;
         cTokens.reportPayouts(questionId, result);
        } 
        /// Finds where in the range defined by upper and lower bounds the price value falls and determines proportional payouts.
          else  {
            uint ratio = value.sub(lowerBound).mul(hundred);
            uint range = upperBound.sub(lowerBound);
            uint longPayout = ratio.div(range);
            result[0] = hundred.sub(longPayout);
            result[1] = longPayout;
        cTokens.reportPayouts(questionId, result);
        }
        
        emit ResolutionSuccessful(questionId, markets[questionId].resolutionTime, block.timestamp, value, result);

    }
  
}