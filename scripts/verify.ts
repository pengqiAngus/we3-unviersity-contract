import { run } from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  console.log("开始验证合约...");

  try {
    // 读取部署信息
    const deploymentPath = path.join(__dirname, "../ignition/deployments");
    const networks = fs.readdirSync(deploymentPath);
    const latestDeployment = networks
      .map((network) => {
        const deployments = fs.readdirSync(path.join(deploymentPath, network));
        return {
          network,
          deployment: deployments[deployments.length - 1],
        };
      })
      .sort((a, b) => {
        return (
          fs
            .statSync(path.join(deploymentPath, b.network, b.deployment))
            .mtime.getTime() -
          fs
            .statSync(path.join(deploymentPath, a.network, a.deployment))
            .mtime.getTime()
        );
      })[0];

    if (!latestDeployment) {
      throw new Error("没有找到部署信息");
    }

    const deploymentFile = path.join(
      deploymentPath,
      latestDeployment.network,
      latestDeployment.deployment,
      "deployments.json"
    );

    if (!fs.existsSync(deploymentFile)) {
      throw new Error(`部署文件不存在: ${deploymentFile}`);
    }

    const deployment = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));

    // 获取合约地址
    const yiDengTokenAddress = deployment.YiDengToken?.address;
    const courseCertificateAddress = deployment.CourseCertificate?.address;
    const courseMarketAddress = deployment.CourseMarket?.address;

    if (
      !yiDengTokenAddress ||
      !courseCertificateAddress ||
      !courseMarketAddress
    ) {
      throw new Error("无法获取所有合约地址");
    }

    console.log("正在验证 YiDengToken...");
    await run("verify:verify", {
      address: yiDengTokenAddress,
      constructorArguments: [],
    });

    console.log("正在验证 CourseCertificate...");
    await run("verify:verify", {
      address: courseCertificateAddress,
      constructorArguments: [],
    });

    console.log("正在验证 CourseMarket...");
    await run("verify:verify", {
      address: courseMarketAddress,
      constructorArguments: [yiDengTokenAddress, courseCertificateAddress],
    });

    console.log("所有合约验证完成！");
    console.log({
      YiDengToken: yiDengTokenAddress,
      CourseCertificate: courseCertificateAddress,
      CourseMarket: courseMarketAddress,
    });
  } catch (error) {
    console.error("验证过程中出错:", error);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
