// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DealClientStorageRenewal.sol";

contract DealClientStorageRenewalTest is Test {
    DealClientStorageRenewal public dealClient;
    bytes testCID;
    string testLabel;
    uint64 piece_size;
    string location_ref;
    uint64 car_size;
    bytes allowedParams = hex"deadbeaf"; // placeholder
    bytes allowedParamsFail = hex"0000"; // placeholder

    function setUp() public {
        dealClient = new DealClientStorageRenewal();
        testCID = hex"000181E2039220206B86B273FF34FCE19D6B804EFF5A3F5747ADA4EAA22F1D49C01E52DDB7875B4B";
        piece_size = 1337;
        car_size = 1337337;
        location_ref = "http://localhost/file.car";
        testLabel = "bafk2bzaceanzppnlffioby4nac2hhjmrstzntqie3oid4ovq6zu4qhhjs4bvy";
    }

    function testCreateDealRequests() public {
        uint len = 4;
        bytes[] memory CIDs = new bytes[](len);
        uint64[] memory piece_sizes = new uint64[](len);
        string[] memory location_refs = new string[](len);
        uint64[] memory car_sizes = new uint64[](len);
        string[] memory labels = new string[](len);
        for (uint i = 0; i < len; i++) {
            CIDs[i] = testCID;
            piece_sizes[i] = piece_size;
            location_refs[i] = location_ref;
            car_sizes[i] = car_size;
            labels[i] = testLabel;
        }

        DealRequest[] memory output = dealClient.createDealRequests(
            CIDs,
            piece_sizes,
            location_refs,
            car_sizes,
            labels
        );
        assert(output.length == 4);
    }

    function testDealRequestCID() public {
        dealClient.createDealRequest(
            testCID,
            piece_size,
            location_ref,
            car_size,
            testLabel
        );
        bytes memory dealCID = dealClient.getDealByIndex(0).piece_cid;
        require(keccak256(testCID) == keccak256(dealCID), string(dealCID));
    }

    function testValid() public {
        dealClient.createDealRequest(
            testCID,
            piece_size,
            location_ref,
            car_size,
            testLabel
        );
        require(dealClient.dealsLength() == 1, "Expect one deal");
    }

    function testNotWithdraw() public {
        vm.expectRevert(bytes("addBalance: Contract not payable"));
        dealClient.addBalance(0);
        vm.expectRevert(bytes("withdrawBalance: Contract not payable"));
        dealClient.withdrawBalance(address(this), 0);
    }

    function testMakeDealProposal() public {
        require(dealClient.dealsLength() == 0, "Expect no deals");
        dealClient.createDealRequest(
            testCID,
            piece_size,
            location_ref,
            car_size,
            testLabel
        );
        require(dealClient.dealsLength() == 1, "Expect one deal");
    }

    function testDealClientConfigAuthenticateMessage() public {
        //todo add white list actor to allowedParams
        uint64 AUTHENTICATE_MESSAGE_METHOD_NUM = 2643134072;
        vm.expectRevert(bytes("msg.sender needs to be market actor f05"));
        dealClient.handle_filecoin_method(
            AUTHENTICATE_MESSAGE_METHOD_NUM,
            0,
            allowedParams
        );
    }

    function testDefaultActorIds() public {
        require(dealClient.isVerifiedSP(8403));
        require(dealClient.isVerifiedSP(22352));
    }

    function testInvalidActorId(uint64 actorId) public {
        vm.assume(actorId != 8403);
        vm.assume(actorId != 22352);
        require(!dealClient.isVerifiedSP(actorId));
    }

    function testInvalidActorIdUint64(uint64 actorId) public {
        vm.assume(actorId != 8403);
        vm.assume(actorId != 22352);
        require(!dealClient.isVerifiedSP(actorId));
    }

    function testAddRemoveActorIdsBatch() public {
        uint64[] memory actorIds = new uint64[](2);
        actorIds[0] = 1111;
        actorIds[1] = 1112;
        uint64 actorIdInvalid = 9999;

        //neither actor id added
        require(!dealClient.isVerifiedSP(actorIds[0]));
        require(!dealClient.isVerifiedSP(actorIds[1]));
        require(!dealClient.isVerifiedSP(actorIdInvalid));

        dealClient.addVerifiedSPs(actorIds);
        require(dealClient.isVerifiedSP(actorIds[0]));
        require(dealClient.isVerifiedSP(actorIds[1]));
        require(!dealClient.isVerifiedSP(actorIdInvalid));

        dealClient.deleteSP(actorIds[0]);
        dealClient.deleteSP(actorIds[1]);
        require(!dealClient.isVerifiedSP(actorIds[0]));
        require(!dealClient.isVerifiedSP(actorIds[1]));
        require(!dealClient.isVerifiedSP(actorIdInvalid));
    }

    function testAddRemoveActorIds() public {
        uint64 actorId = 1111;
        uint64 actorIdInvalid = 9999;

        //neither actor id added
        require(!dealClient.isVerifiedSP(actorId));
        require(!dealClient.isVerifiedSP(actorIdInvalid));

        dealClient.addVerifiedSP(actorId);
        require(dealClient.isVerifiedSP(actorId));
        require(!dealClient.isVerifiedSP(actorIdInvalid));

        dealClient.deleteSP(actorId);
        require(!dealClient.isVerifiedSP(actorId));
        require(!dealClient.isVerifiedSP(actorIdInvalid));
    }
}
