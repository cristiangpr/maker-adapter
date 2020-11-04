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
  function getPrice() public view returns (uint) {
    address ethUsdPriceFeed = 0x729D19f657BD0614b4985Cf1D82531c67569197B;
     return uint(
      IMakerPriceFeed(ethUsdPriceFeed).read()
    );
    
  }

    
    function resolveValue(bytes32 questionId, uint targetValue, uint resolutionTime) external {
        require(
            block.timestamp >= resolutionTime,
            "Please submit a resolution during the correct time interval"
        );

        uint value = getPrice();
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