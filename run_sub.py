#!/usr/bin/env python3
"""WAUV Isaac Sim runtime (minimal).

    docker compose --profile run up sim-run

Opens the pool stage (or a test scene), places a ZED X Mini, streams it to the ZED SDK
on port 30000 and runs the sim loop. No physics/bridge yet.
"""
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("--stage", default="/assets/wauv_pool.usda", help="root stage; test scene if missing")
parser.add_argument("--zed-prim", default="/World/ZED_XM")
parser.add_argument("--port", type=int, default=30000)
parser.add_argument("--underwater", action="store_true", help="turn the ZED underwater filter on")
args, _ = parser.parse_known_args()

import numpy as np
from isaacsim import SimulationApp

app = SimulationApp({"headless": True})

import carb 
import omni.graph.core as og
import omni.kit.app
import omni.usd
import usdrt
from isaacsim.core.utils.extensions import enable_extension

ext_mgr = omni.kit.app.get_app().get_extension_manager()
ext_mgr.add_path("/isaac-sim/extsUser/zed-isaac-sim/exts")
for ext in ("omni.kit.livestream.webrtc",
            "sl.sensor.camera",     #zed camera
            "isaacsim.ros2.bridge"):
    enable_extension(ext)
app.update()                                                 # let them start

carb.settings.get_settings().set("/exts/sl.sensor.camera/underwater/enabled", args.underwater)

from isaacsim.core.api import World
from isaacsim.core.experimental.objects import DomeLight, GroundPlane
from isaacsim.core.experimental.prims import XformPrim
from isaacsim.core.experimental.utils.stage import add_reference_to_stage, define_prim
from isaacsim.core.utils.stage import is_stage_loading, open_stage
from sl.sensor.camera.utils import get_camera_usd_path, select_lens_variant


# ---------------------------------------------------------------- scene


if os.path.isfile(args.stage):
    open_stage(args.stage)
    while is_stage_loading():
        app.update()
else:
    carb.log_warn(f"[WAUV] {args.stage} not found: building a test scene")
    DomeLight("/World/DomeLight").set_intensities(500)
    GroundPlane("/World/Ground", sizes=50.0)

# ZED X Mini: reference the shipped model so the stereo baseline/intrinsics are real.
if not omni.usd.get_context().get_stage().GetPrimAtPath(args.zed_prim).IsValid():
    define_prim(args.zed_prim)
    prim = add_reference_to_stage(get_camera_usd_path("ZED_XM"), args.zed_prim)
    select_lens_variant(prim.GetStage(), args.zed_prim, "ZED_XM")
    XformPrim(args.zed_prim, positions=(0.0, 0.0, 1.0), reset_xform_op_properties=True)





og.Controller.edit(
    {"graph_path": "/World/ZEDGraph", "evaluator_name": "execution"},
    {
        og.Controller.Keys.CREATE_NODES: [
            ("tick", "omni.graph.action.OnPlaybackTick"),
            ("zed", "sl.sensor.camera.ZED_Camera"),          # "ZED Camera Helper" in the UI
        ],
        og.Controller.Keys.CONNECT: [("tick.outputs:tick", "zed.inputs:execIn")],
        og.Controller.Keys.SET_VALUES: [
            ("zed.inputs:cameraPrim", [usdrt.Sdf.Path(args.zed_prim)]),
            ("zed.inputs:streamingPort", args.port),
        ],
    },
)






world = World(stage_units_in_meters=1.0, physics_dt=1.0 / 240.0, rendering_dt=1.0 / 30.0)
world.reset()
world.play()
print(f"[WAUV] running: ZED on port {args.port}, underwater={args.underwater}")

try:
    while app.is_running():
        world.step(render=True)
finally:
    app.close()
