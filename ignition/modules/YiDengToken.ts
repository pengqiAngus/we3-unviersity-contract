import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("YiDengToken", (m) => {
  const token = m.contract("YiDengToken");

  return { token };
});
