"""Publish TIO's provisional URDF and zero-position joint states for RViz2."""

from pathlib import Path

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node
import xacro


def generate_launch_description():
    package_share = Path(get_package_share_directory("tio_description"))
    model_path = package_share / "urdf" / "tio.urdf.xacro"
    robot_xml = xacro.process_file(str(model_path)).toxml()

    return LaunchDescription(
        [
            Node(
                package="robot_state_publisher",
                executable="robot_state_publisher",
                name="tio_robot_state_publisher",
                output="screen",
                parameters=[{"robot_description": robot_xml, "use_sim_time": False}],
            ),
            Node(
                package="joint_state_publisher",
                executable="joint_state_publisher",
                name="tio_joint_state_publisher",
                output="screen",
                parameters=[{"rate": 20.0, "use_sim_time": False}],
            ),
        ]
    )
