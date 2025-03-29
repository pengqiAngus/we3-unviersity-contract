import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const WAIT_CONFIRMATIONS = 5; // 等待5个区块确认

export default buildModule("YiDengEducation", (m) => {
  // 部署 YiDengToken
  const yiDengToken = m.contract("YiDengToken", [], {
    // 等待确认，以便获得准确的合约地址
    waitConfirmations: WAIT_CONFIRMATIONS,
  });

  // 部署 CourseCertificate
  const courseCertificate = m.contract("CourseCertificate", [], {
    waitConfirmations: WAIT_CONFIRMATIONS,
  });

  // 部署 CourseMarket，并传入依赖的合约地址
  const courseMarket = m.contract(
    "CourseMarket",
    [
      m.getAddress(yiDengToken), // 使用 getAddress 获取已部署合约的地址
      m.getAddress(courseCertificate),
    ],
    {
      waitConfirmations: WAIT_CONFIRMATIONS,
    }
  );

  // 设置 CourseCertificate 的 MINTER_ROLE 给 CourseMarket
  const setMinterRole = m.call(courseCertificate, "grantRole", [
    m.staticCall(courseCertificate, "MINTER_ROLE"),
    m.getAddress(courseMarket),
  ]);

  // 返回所有部署的合约
  return {
    yiDengToken,
    courseCertificate,
    courseMarket,
    setMinterRole,
  };
});
