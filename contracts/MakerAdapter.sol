pragma solidity ^0.6.0;
import { ConditionalTokens } from "./ConditionalTokens.sol";
import { SafeMath } from "./SafeMath.sol";

///@dev interface to read price oracles
interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}

contract MakerAdapter {
     using SafeMath for uint256;
     ConditionalTokens public cTokens;
   
  

    /// @dev Emitted upon the successful reporting of whether the actual value has exceeded target to the conditional tokens contract.
    /// @param resolutionTime Beginning of time window in which valid reports may be generated. 
    /// @param currentTime Time at which this oracle made a determination of the value.
    /// @param value price reported by oracle.
    /// @param result The array of uints representing the result.
    event ResolutionSuccessful(uint resolutionTime, uint currentTime, uint value, uint[] result);
    ///@dev Emitted upon market preparation
    event MarketPrepared(bytes32 conditionId, uint resolutionTime, uint targetValue, uint variation);
    
      /// Mapping key is a condition ID. Array contains values to be used for market resolution. 
    mapping(bytes32 => uint[]) public conditionValues;
    
     /// Mapping key is a condition ID. Value is address of price oracle to be used
    mapping(bytes32 => address) public conditionPriceFeed;
    
    constructor (
        /// @param address of conditional tokens contract to be used
        ConditionalTokens _cTokens
      
    ) public {
        cTokens = _cTokens;
    
       
    }
    ///@dev Function defines values to be used for market resolution.
    ///@param conditionId from the conditional tokens contract getConditionId function. For adapter to work outcome slots should be set to 2, index set for short outcome set to 1 and index set for long outcome to 2. 
    ///@param resolutionTime timestamp of start of valid market resolution window
    ///@param priceFeed address of token price oracle. 0x729D19f657BD0614b4985Cf1D82531c67569197B is the address of Maker DAO eth-usd feed. More options will be availabe when contract is whitelisted.
    ///@param targetValue predicted token price
    ///@param variation  To define a binary market set to 0. To define a scalar market set to desired plus and minus range. Bounds are equal to targetValue +- variation.
  function prepareMarket(bytes32 conditionId, uint resolutionTime, address priceFeed, uint targetValue, uint variation) external {
      require(resolutionTime >= block.timestamp,  "Please submit a resolution time in the future");
      require(conditionValues[conditionId].length == 0, "market already prepared");
      conditionPriceFeed[conditionId] = priceFeed;
      conditionValues[conditionId] = new uint[](3);
      conditionValues[conditionId][0] = targetValue;
      conditionValues[conditionId][1] = variation;
      conditionValues[conditionId][2] = resolutionTime;
      
      
       emit MarketPrepared(conditionId, resolutionTime, targetValue, variation);
  }
   ///@dev reads the price of the token
   //@param priceFeed address of relevant Maker DAO price feed. Defined at market preparation. 
   
  function getPrice(address priceFeed) internal view returns (uint) {
    
       return uint(
      IMakerPriceFeed(priceFeed).read()
    );
    
  }
    ///@dev resolves market by getting price from feed, comparing to target value and calling Conditional Tokens reportPayouts function with an array of uints representing payout numerators.
    ///@param questionId used in conditional tokens condition preparation
    ///@param conditionId from the conditional tokens contract getConditionId function
    function resolveMarket(bytes32 questionId, bytes32 conditionId) external {
      require(conditionValues[conditionId][2] <= block.timestamp, "resolution window has not begun");
      
        ///@param value oracle's response
        uint value = getPrice(conditionPriceFeed[conditionId]);
        uint targetValue = conditionValues[conditionId][0];
        uint variation = conditionValues[conditionId][1];
        uint lowerBound = targetValue.sub(variation);
        uint upperBound = targetValue.add(variation);
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
            uint a = value.sub(lowerBound).mul(hundred);
            uint b = upperBound.sub(lowerBound);
            uint c = a.div(b);
            result[0] = hundred.sub(c);
            result[1] = c;
        cTokens.reportPayouts(questionId, result);
        }
        
        emit ResolutionSuccessful(conditionValues[conditionId][2], block.timestamp, value, result);

    }
  
}