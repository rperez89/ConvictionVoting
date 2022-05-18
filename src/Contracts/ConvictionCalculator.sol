// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ConvictionCalculator is Ownable {
  using SafeMath for uint256;

  uint256 constant public D = 10000000;
  uint256 constant private TWO_128 = 0x100000000000000000000000000000000; // 2^128
  uint256 constant private TWO_127 = 0x80000000000000000000000000000000; // 2^127

    /**
     * Multiply _a by _b / 2^128.  Parameter _a should be less than or equal to
     * 2^128 and parameter _b should be less than 2^128.
     * @param _a left argument
     * @param _b right argument
     * @return _result
     */
    function _mul(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
        require(_a <= TWO_128, "_a should be less than or equal to 2^128");
        require(_b < TWO_128, "_b should be less than 2^128");
        _result = _a.mul(_b).add(TWO_127) >> 128;
        return _result;
    }

    /**
    * Calculate (_a / 2^128)^_b * 2^128.  Parameter _a should be less than 2^128.
    *
    * @param _a left argument
    * @param _b right argument
    * @return _result (_a / 2^128)^_b * 2^128
    */
  function _pow(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
      require(_a < TWO_128, "_a should be less than 2^128");
      uint256 a = _a;
      uint256 b = _b;
      _result = TWO_128;
      while (b > 0) {
          if (b & 1 == 0) {
              a = _mul(a, a);
              b >>= 1;
          } else {
              _result = _mul(_result, a);
              b -= 1;
          }
      }
  }

    /**
    * @dev Conviction formula: a^t * y(0) + x * (1 - a^t) / (1 - a)
    * Solidity implementation: y = (2^128 * a^t * y0 + x * D * (2^128 - 2^128 * a^t) / (D - aD) + 2^127) / 2^128
    * @param _timePassed Number of blocks since last conviction record
    * @param _lastConv Last conviction record
    * @param _oldAmount Amount of tokens staked until now
    * @return Current conviction
    */
function calculateConviction(
        uint256 _timePassed,
        uint256 _lastConv,
        uint256 _oldAmount,
        uint256 _decay
    )
        public pure returns(uint256)
    {
        uint256 t = uint256(_timePassed);
        // atTWO_128 = 2^128 * a^t
        uint256 atTWO_128 = _pow((_decay << 128).div(D), t);
        // solium-disable-previous-line
        // conviction = (atTWO_128 * _lastConv + _oldAmount * D * (2^128 - atTWO_128) / (D - aD) + 2^127) / 2^128
        return (atTWO_128.mul(_lastConv).add(_oldAmount.mul(D).mul(TWO_128.sub(atTWO_128)).div(D - _decay))).add(TWO_127) >> 128;
    }
}
