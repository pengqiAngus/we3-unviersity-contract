import { expect } from "chai";
import { ethers } from "hardhat";
import {
  CourseMarket,
  YiDengToken,
  CourseCertificate,
} from "../../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("CourseMarket", function () {
  let courseMarket: CourseMarket;
  let yiDengToken: YiDengToken;
  let certificate: CourseCertificate;
  let owner: SignerWithAddress;
  let creator: SignerWithAddress;
  let student: SignerWithAddress;

  const WEB2_COURSE_ID = "COURSE-001";
  const COURSE_NAME = "Web3 Development";
  const COURSE_PRICE = 100;
  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));

  beforeEach(async function () {
    [owner, creator, student] = await ethers.getSigners();

    // 部署 YiDengToken
    const YiDengToken = await ethers.getContractFactory("YiDengToken");
    yiDengToken = await YiDengToken.deploy();
    await yiDengToken.waitForDeployment();

    // 部署 CourseCertificate
    const CourseCertificate = await ethers.getContractFactory(
      "CourseCertificate"
    );
    certificate = await CourseCertificate.deploy();
    await certificate.waitForDeployment();

    // 部署 CourseMarket
    const CourseMarket = await ethers.getContractFactory("CourseMarket");
    courseMarket = await CourseMarket.deploy(
      await yiDengToken.getAddress(),
      await certificate.getAddress()
    );
    await courseMarket.waitForDeployment();

    // 授予 CourseMarket 铸造证书的权限
    await certificate.grantRole(MINTER_ROLE, await courseMarket.getAddress());

    // 为学生提供一些代币
    await yiDengToken
      .connect(student)
      .buyWithETH({ value: ethers.parseEther("1") });
    await yiDengToken
      .connect(student)
      .approve(await courseMarket.getAddress(), ethers.MaxUint256);
  });

  describe("Course Management", function () {
    it("Should add a new course", async function () {
      await expect(
        courseMarket.addCourse(WEB2_COURSE_ID, COURSE_NAME, COURSE_PRICE)
      )
        .to.emit(courseMarket, "CourseAdded")
        .withArgs(1, WEB2_COURSE_ID, COURSE_NAME);

      const course = await courseMarket.courses(1);
      expect(course.web2CourseId).to.equal(WEB2_COURSE_ID);
      expect(course.name).to.equal(COURSE_NAME);
      expect(course.price).to.equal(COURSE_PRICE);
      expect(course.isActive).to.be.true;
      expect(course.creator).to.equal(owner.address);
    });

    it("Should not add duplicate course", async function () {
      await courseMarket.addCourse(WEB2_COURSE_ID, COURSE_NAME, COURSE_PRICE);
      await expect(
        courseMarket.addCourse(WEB2_COURSE_ID, COURSE_NAME, COURSE_PRICE)
      ).to.be.revertedWith("Course already exists");
    });
  });

  describe("Course Purchase", function () {
    beforeEach(async function () {
      await courseMarket.addCourse(WEB2_COURSE_ID, COURSE_NAME, COURSE_PRICE);
    });

    it("Should allow student to purchase course", async function () {
      await expect(courseMarket.connect(student).purchaseCourse(WEB2_COURSE_ID))
        .to.emit(courseMarket, "CoursePurchased")
        .withArgs(student.address, 1, WEB2_COURSE_ID);

      expect(await courseMarket.hasCourse(student.address, WEB2_COURSE_ID)).to
        .be.true;
    });

    it("Should not allow double purchase", async function () {
      await courseMarket.connect(student).purchaseCourse(WEB2_COURSE_ID);
      await expect(
        courseMarket.connect(student).purchaseCourse(WEB2_COURSE_ID)
      ).to.be.revertedWith("Already purchased");
    });
  });

  describe("Course Completion", function () {
    beforeEach(async function () {
      await courseMarket.addCourse(WEB2_COURSE_ID, COURSE_NAME, COURSE_PRICE);
      await courseMarket.connect(student).purchaseCourse(WEB2_COURSE_ID);
    });

    it("Should verify course completion and mint certificate", async function () {
      await expect(
        courseMarket.verifyCourseCompletion(student.address, WEB2_COURSE_ID)
      ).to.emit(courseMarket, "CourseCompleted");

      expect(await certificate.hasCertificate(student.address, WEB2_COURSE_ID))
        .to.be.true;
    });

    it("Should not verify completion for unpurchased course", async function () {
      await expect(
        courseMarket.verifyCourseCompletion(creator.address, WEB2_COURSE_ID)
      ).to.be.revertedWith("Course not purchased");
    });

    it("Should handle batch completion verification", async function () {
      const students = [student.address];
      await courseMarket.batchVerifyCourseCompletion(students, WEB2_COURSE_ID);
      expect(await certificate.hasCertificate(student.address, WEB2_COURSE_ID))
        .to.be.true;
    });
  });
});
