module.exports = async ({ getNamedAccounts, deployments }) => {
  {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    log(`Deployer: ${deployer}`);

    const crw = await deploy("CRWCP", {
      from: deployer,
      log: true,
    });

    log(`The contract address is ${crw.address}.`);
  }
};
