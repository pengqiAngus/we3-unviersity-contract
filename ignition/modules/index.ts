import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("YiDengPlatform", (m) => {
  // 部署 YiDengToken
  const token = m.contract("YiDengToken");

  // 部署 CourseCertificate
  const certificate = m.contract("CourseCertificate");

  // 部署 CourseMarket
  const market = m.contract("CourseMarket", [token, certificate]);

  return {
    token,
    certificate,
    market,
  };
});
