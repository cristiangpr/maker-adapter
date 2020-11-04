pragma solidity ^0.6.0;
import { ConditionalTokens } from "./ConditionalTokens.sol";

interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}

contract MakerAdapter {
     ConditionalTokens public cTokens;
   
  

    /// @dev Emitted upon the successful reporting of whether the actual value has exceeded target to the conditional tokens contract.
    /// @param resolutionTime Beginning of time window in which valid reports may be generated. 
    /// @param currentTime Time at which this oracle made a determination of the value.
    /// @param result The array of uints representing the result.
    event ResolutionSuccessful(uint resolutionTime, uint currentTime, uint[] result);
    
    constructor (
        ConditionalTokens _cTokens
      
    ) public {
        cTokens = _cTokens;
    
       
    }
   ///@dev reads the price of the token
   ///@param priceFeed address of relevant Maker DAO price feed 
   /// address ethUsdPriceFeed = 0x729D19f657BD0614b4985Cf1D82531c67569197B;
  function getPrice(address priceFeed) internal view returns (uint) {
    
     return uint(
      IMakerPriceFeed(priceFeed).read()
    );
    
  }
   ///@dev resolves market by getting price from feed, comparing to target value and calling Conditional Tokens reportPayouts
    ///@param targetValue price to compare to current price
    function resolveMarket(bytes32 questionId, address priceFeed, uint targetValue, uint resolutionTime) external {
        require(
            block.timestamp >= resolutionTime,
            "Please submit a resolution during the correct time interval"
        );

        uint value = getPrice(priceFeed);
        uint[] memory result = new uint[](2);
        
        if (value > targetValue) {
              result[0] = 1;
              result[1] = 0;
              cTokens.reportPayouts(questionId, result);
        } else {
             result[0] = 0;
             result[1] = 1;
             cTokens.reportPayouts(questionId, result);
        }
        emit ResolutionSuccessful(resolutionTime, block.timestamp, result);
    }
  
}