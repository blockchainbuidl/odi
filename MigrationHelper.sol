// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "./interfaces/IBEP20.sol";



interface IMasterChef {
    function owner() external view returns (address);
    function poolInfo(uint256 _pid) external view returns (IBEP20,uint256, uint256, uint256);
    function poolLength() external view returns (uint256);
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;
    function updatePool(uint256 _pid) external;
    function transferOwnership(address newOwner) external;
}

contract MigrationHelper is Ownable {

    address immutable public MasterChefV1Addr;

    address immutable public MasterChefV1OriginOwner;

    uint256 immutable public MasterChefV2Pid;

    bool public isBackupAllocPoints;

    uint256 public totalAllocPoints;

    mapping(uint256 => uint256) public prevAllocPoints;

    uint256[] public localPools;

    constructor(
        address _MasterChefV1Addr,
        uint256 _MasterChefV2Pid
    ) public {
        MasterChefV1Addr = _MasterChefV1Addr;
        MasterChefV1OriginOwner = IMasterChef(_MasterChefV1Addr).owner();
        MasterChefV2Pid = _MasterChefV2Pid;
    }

    function addPoolToMigrate(uint256[] memory pools) external onlyOwner {
        for (uint256 i; i < pools.length; i++) {
            // get pid of the pools array
            uint256 pid = pools[i];

            require(prevAllocPoints[pid] == 0, "pid already set");

            (, uint256 allocPoint, ,) = IMasterChef(MasterChefV1Addr).poolInfo(pid);

            if (allocPoint > 0) {
                totalAllocPoints = totalAllocPoints + allocPoint;
                prevAllocPoints[pid] = allocPoint;
                localPools.push(pid);
            }
        }
    }

    function removePoolToMigrate(uint256[] memory pools) external onlyOwner {
        for (uint256 i; i < pools.length; i++) {
            // get pid of the pools array
            uint256 pid = pools[i];

            (, uint256 allocPoint, ,) = IMasterChef(MasterChefV1Addr).poolInfo(pid);

            if (allocPoint > 0) {
                totalAllocPoints = totalAllocPoints - allocPoint;
            }

            prevAllocPoints[pid] = 0;
        }
    }

    function hasBackupAllocPoints(bool _status) external onlyOwner {
        isBackupAllocPoints = _status;
    }

    function transferOwnershipForMasterChefV1() external onlyOwner {
        IMasterChef(MasterChefV1Addr).transferOwnership(MasterChefV1OriginOwner);
    }

    function set(uint256 _pid) external onlyOwner {
        require(isBackupAllocPoints, "has not backup allocPoints yet");

        _updatePool(_pid);

        // set allocPoint to 0 except MCv2Pid to 1
        if (_pid == MasterChefV2Pid) {
            IMasterChef(MasterChefV1Addr).set(_pid, 1, false);
        } else if (prevAllocPoints[_pid] > 0) {
            IMasterChef(MasterChefV1Addr).set(_pid, 0, false);
        }
    }

    function batchSet(uint256[] memory pools) external onlyOwner {
        require(isBackupAllocPoints, "has not backup allocPoints yet");

        for (uint256 i; i < pools.length; i++) {
            // get pid of the pools array
            uint256 pid = pools[i];
            // update pool
            _updatePool(pid);
        }

        for (uint256 i; i < pools.length; i++) {
            // get pid of the pools array
            uint256 pid = pools[i];
            // set allocPoint to 0 except MCv2Pid to 1
            if (pid == MasterChefV2Pid) {
                IMasterChef(MasterChefV1Addr).set(pid, 1, false);
            } else if (prevAllocPoints[pid] > 0) {
                IMasterChef(MasterChefV1Addr).set(pid, 0, false);
            }
        }
    }

    function recover(uint256 _pid) external onlyOwner {
        require(isBackupAllocPoints, "has not backup allocPoints yet");

        _updatePool(_pid);

        if (prevAllocPoints[_pid] > 0) {
            IMasterChef(MasterChefV1Addr).set(_pid, prevAllocPoints[_pid], false);
        }
    }

    function batchRecover(uint256[] memory pools) external onlyOwner {
        require(isBackupAllocPoints, "has not backup allocPoints yet");

        for (uint256 i; i < pools.length; i++) {
            // get pid of the pools array
            uint256 pid = pools[i];
            // update pool
            _updatePool(pid);
        }

        for (uint256 i; i < pools.length; i++) {
            // get pid of the pools array
            uint256 pid = pools[i];
            // set allocPoint back to origin value
            if (prevAllocPoints[pid] > 0) {
                IMasterChef(MasterChefV1Addr).set(pid, prevAllocPoints[pid], false);
            }
        }
    }

    function kill() external onlyOwner {
        require(MasterChefV1OriginOwner == IMasterChef(MasterChefV1Addr).owner(),
            "should not hold MasterChefV1 ownership"
        );

        selfdestruct(msg.sender);
    }

    function _updatePool(uint256 _pid) internal {
        require(_pid > 0, "pid0 is not settable");

        IMasterChef(MasterChefV1Addr).updatePool(_pid);
    }
}