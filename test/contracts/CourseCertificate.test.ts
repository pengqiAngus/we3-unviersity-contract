import { expect } from "chai";
import { ethers } from "hardhat";
import { CourseCertificate } from "../../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("CourseCertificate", function () {
  let certificate: CourseCertificate;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let student: SignerWithAddress;
  let nonMinter: SignerWithAddress;

  const WEB2_COURSE_ID = "COURSE-001";
  const METADATA_URI = "https://api.yideng.com/certificate/COURSE-001/metadata";
  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));

  beforeEach(async function () {
    [owner, minter, student, nonMinter] = await ethers.getSigners();

    const CourseCertificate = await ethers.getContractFactory(
      "CourseCertificate"
    );
    certificate = await CourseCertificate.deploy();
    await certificate.waitForDeployment();

    // 授予铸造者权限
    await certificate.grantRole(MINTER_ROLE, minter.address);
  });

  describe("Deployment", function () {
    it("Should set the right name and symbol", async function () {
      expect(await certificate.name()).to.equal("YiDeng Course Certificate");
      expect(await certificate.symbol()).to.equal("YDCC");
    });

    it("Should set the right roles", async function () {
      expect(await certificate.hasRole(MINTER_ROLE, minter.address)).to.be.true;
      expect(
        await certificate.hasRole(
          await certificate.DEFAULT_ADMIN_ROLE(),
          owner.address
        )
      ).to.be.true;
    });
  });

  describe("Certificate Minting", function () {
    it("Should allow minter to mint certificate", async function () {
      await expect(
        certificate
          .connect(minter)
          .mintCertificate(student.address, WEB2_COURSE_ID, METADATA_URI)
      )
        .to.emit(certificate, "CertificateMinted")
        .withArgs(1, WEB2_COURSE_ID, student.address);

      expect(await certificate.ownerOf(1)).to.equal(student.address);
      expect(await certificate.hasCertificate(student.address, WEB2_COURSE_ID))
        .to.be.true;
    });

    it("Should not allow non-minter to mint certificate", async function () {
      await expect(
        certificate
          .connect(nonMinter)
          .mintCertificate(student.address, WEB2_COURSE_ID, METADATA_URI)
      ).to.be.reverted;
    });

    it("Should not mint to zero address", async function () {
      await expect(
        certificate
          .connect(minter)
          .mintCertificate(ethers.ZeroAddress, WEB2_COURSE_ID, METADATA_URI)
      ).to.be.revertedWith("Invalid student address");
    });
  });

  describe("Certificate Queries", function () {
    beforeEach(async function () {
      await certificate
        .connect(minter)
        .mintCertificate(student.address, WEB2_COURSE_ID, METADATA_URI);
    });

    it("Should return correct token URI", async function () {
      expect(await certificate.tokenURI(1)).to.equal(METADATA_URI);
    });

    it("Should correctly check certificate ownership", async function () {
      expect(await certificate.hasCertificate(student.address, WEB2_COURSE_ID))
        .to.be.true;
      expect(
        await certificate.hasCertificate(nonMinter.address, WEB2_COURSE_ID)
      ).to.be.false;
    });

    it("Should return student certificates", async function () {
      const certificates = await certificate.getStudentCertificates(
        student.address,
        WEB2_COURSE_ID
      );
      expect(certificates.length).to.equal(1);
      expect(certificates[0]).to.equal(1);
    });
  });

  describe("Multiple Certificates", function () {
    it("Should handle multiple certificates for same course", async function () {
      await certificate
        .connect(minter)
        .mintCertificate(student.address, WEB2_COURSE_ID, METADATA_URI);
      await certificate
        .connect(minter)
        .mintCertificate(student.address, WEB2_COURSE_ID, METADATA_URI + "/2");

      const certificates = await certificate.getStudentCertificates(
        student.address,
        WEB2_COURSE_ID
      );
      expect(certificates.length).to.equal(2);
    });
  });
});
