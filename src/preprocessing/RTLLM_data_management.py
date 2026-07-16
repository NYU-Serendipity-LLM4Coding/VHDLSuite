"""
RTLLM dataset acquisition and preprocessing.

Downloads the RTLLM v2.0 benchmark and flattens its three-level hierarchy
into the single-level layout VHDLSuite expects.

The raw RTLLM v2.0 release organizes designs in three levels:

    RTLLM/
      Arithmetic/          <- level 1: functional category
        <group>/           <- level 2: design group
          <design>/        <- level 3: the actual problem directory
            design_description.txt, testbench.v, verified_verilog.v, ...

This script walks that hierarchy in a fixed order (categories in the order
listed in LEVEL1_FOLDERS, then case-insensitive alphabetical sort at levels 2
and 3) and copies each level-3 directory to:

    Prob<NNN>_<category>_<group>_<design>

The numeric prefix comes from enumeration order. Because the traversal order
is deterministic, re-running always yields identical problem IDs -- which is
what the evaluation and analysis stages rely on to join results across runs.

Run from the repository root:

    python src/preprocessing/rtllm_data_management.py
"""

import shutil
import subprocess
from pathlib import Path

RTLLM_REPO = "https://github.com/hkust-zhiyao/RTLLM"
RTLLM_DIR = "data/RTLLM"
OUTPUT_FOLDER = "data/RTLLM_merged_folders"

# Level-1 category directories, in enumeration order.
# This order determines the assigned Prob### IDs -- do not reorder.
LEVEL1_FOLDERS = [
    "Arithmetic",
    "Control",
    "Memory",
    "Miscellaneous",
]


def download_rtllm(rtllm_dir):
    """Clone the RTLLM benchmark, unless it is already present."""
    rtllm_path = Path(rtllm_dir)

    if rtllm_path.exists():
        print(f"{rtllm_dir} already exists, skipping download")
        return

    rtllm_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"Cloning {RTLLM_REPO} -> {rtllm_dir}")
    subprocess.run(["git", "clone", RTLLM_REPO, str(rtllm_path)], check=True)
    print("Download complete")


def extract_and_rename_folders(level1_folders, rtllm_dir, output_folder):
    """Flatten the RTLLM hierarchy into deterministically named folders.

    Args:
        level1_folders: list of level-1 category names, in enumeration order
        rtllm_dir: path to the raw RTLLM directory
        output_folder: destination for the flattened problem folders
    """
    output_path = Path(output_folder)
    output_path.mkdir(parents=True, exist_ok=True)

    all_level3_folders = []

    for level1_name in level1_folders:
        level1_path = Path(rtllm_dir) / level1_name

        if not level1_path.is_dir():
            print(f"Warning: level-1 folder '{level1_name}' not found, skipping")
            continue

        level2_folders = sorted(
            (f for f in level1_path.iterdir() if f.is_dir()),
            key=lambda x: x.name.lower(),
        )

        for level2_path in level2_folders:
            level3_folders = sorted(
                (f for f in level2_path.iterdir() if f.is_dir()),
                key=lambda x: x.name.lower(),
            )

            for level3_path in level3_folders:
                all_level3_folders.append({
                    "level1": level1_path.name,
                    "level2": level2_path.name,
                    "level3": level3_path.name,
                    "source_path": level3_path,
                })

    for idx, folder_info in enumerate(all_level3_folders, start=1):
        new_name = (
            f"Prob{idx:03d}_{folder_info['level1']}"
            f"_{folder_info['level2']}_{folder_info['level3']}"
        )
        dest_path = output_path / new_name

        try:
            shutil.copytree(folder_info["source_path"], dest_path)
            print(f"Copied: {new_name}")
        except Exception as e:
            print(f"Error: failed to copy {folder_info['source_path']} - {e}")

    print(f"\nDone. Processed {len(all_level3_folders)} design folders.")
    print(f"Output folder: {output_path.absolute()}")


if __name__ == "__main__":
    download_rtllm(RTLLM_DIR)
    extract_and_rename_folders(LEVEL1_FOLDERS, RTLLM_DIR, OUTPUT_FOLDER)