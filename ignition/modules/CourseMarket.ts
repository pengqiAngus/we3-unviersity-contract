import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export const CourseMarket = buildModule("CourseMarket", (m) => {
  const token = m.getParameter<string>("token");
  const certificate = m.getParameter<string>("certificate");

  // 部署 CourseMarket
  const market = m.contract("CourseMarket", [token, certificate]);

  return { market };
});
