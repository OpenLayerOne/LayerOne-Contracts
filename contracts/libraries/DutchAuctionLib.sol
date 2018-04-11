pragma solidity ^0.4.19;

library DutchAuctionLib {
    /*
        Taken mostly from cryptokitties
    */
    function dutchAuctionPrice(
        uint256 _startDate,
        uint256 _duration,
        uint256 _startingPrice,
        uint256 _endingPrice
    )
        public
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        if (now > _startDate) {
            secondsPassed = now - _startDate;
        }

        if (secondsPassed >= _duration) {
            // We've reached the end, return the end price.
            return _endingPrice;
        } else {
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }
}