require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require('hardhat-deploy');
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks:{
    sepolia : {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts : [process.env.PK]
    }
  }
};
