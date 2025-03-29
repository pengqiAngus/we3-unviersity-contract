import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CourseCertificate", (m) => {
  const certificate = m.contract("CourseCertificate");

  return { certificate };
});
