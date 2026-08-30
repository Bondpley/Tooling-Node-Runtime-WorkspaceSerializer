# --==========================================================================-- #
# --                Tooling Node Runtime WorkspaceSerializer                  -- #
# ------------------------------------------------------------------------------ #
# --   https://github.com/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer   -- #
# --                               By Bondpley                                -- #
# --                                  v.1.3                                   -- #
# --==========================================================================-- #

import json
import sys
import re
from xml.sax.saxutils import escape

material_ids = {
    "Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Wood": 512,
    "WoodPlanks": 528, "Marble": 784, "Basalt": 788, "Slate": 800,
    "CrackedLava": 804, "Concrete": 816, "Limestone": 820, "Granite": 832,
    "Pavement": 836, "Brick": 848, "Pebble": 864, "Cobblestone": 880,
    "Rock": 896, "Sandstone": 912, "CorrodedMetal": 1040,
    "DiamondPlate": 1056, "Foil": 1072, "Metal": 1088, "Grass": 1280,
    "LeafyGrass": 1284, "Sand": 1296, "Fabric": 1312, "Snow": 1328,
    "Mud": 1344, "Ground": 1360, "Asphalt": 1376, "Salt": 1392,
    "Ice": 1536, "Glacier": 1552, "Glass": 1568, "ForceField": 1584,
    "Air": 1792, "Water": 2048, "Cardboard": 2304, "Carpet": 2305,
    "CeramicTiles": 2306, "ClayRoofTiles": 2307, "RoofShingles": 2308,
    "Leather": 2309, "Plaster": 2310, "Rubber": 2311
}

enum_tables = {
    "Material": material_ids,
    "PartType": {"Ball": 0, "Block": 1, "Cylinder": 2, "Wedge": 3, "CornerWedge": 4},
    "NormalId": {"Right": 0, "Top": 1, "Back": 2, "Left": 3, "Bottom": 4, "Front": 5},
    "ResamplerMode": {"Default": 0, "Pixelated": 1},
    "SurfaceType": {
        "Smooth": 0, "Glue": 1, "Weld": 2, "Studs": 3, "Inlet": 4,
        "Universal": 5, "Hinge": 6, "Motor": 7, "SteppingMotor": 8,
        "SmoothNoOutlines": 10
    },
    "FormFactor": {"Symmetric": 0, "Brick": 1, "Plate": 2, "Custom": 3},
    "Font": {
        "Legacy": 0, "Arial": 1, "ArialBold": 2, "SourceSans": 3,
        "SourceSansBold": 4, "SourceSansSemibold": 15, "SourceSansLight": 9,
        "SourceSansItalic": 16
    },
    "TextXAlignment": {"Left": 0, "Right": 1, "Center": 2},
    "TextYAlignment": {"Top": 0, "Center": 1, "Bottom": 2},
    "HorizontalAlignment": {"Center": 0, "Left": 1, "Right": 2},
    "VerticalAlignment": {"Center": 0, "Top": 1, "Bottom": 2},
    "AutomaticSize": {"None": 0, "X": 1, "Y": 2, "XY": 3},
    "ProximityPromptStyle": {"Default": 0, "Custom": 1},
    "ParticleOrientation": {
        "FacingCamera": 0, "FacingCameraWorldUp": 1,
        "VelocityParallel": 2, "VelocityPerpendicular": 3
    },
    "ParticleEmitterShape": {"Box": 0, "Sphere": 1, "Cylinder": 2, "Disc": 3},
    "SurfaceGuiShape": {"Flat": 0, "Curved": 1},
    "SizeConstraint": {"RelativeXY": 0, "RelativeXX": 1, "RelativeYY": 2},
    "FrameStyle": {
        "Custom": 0, "ChatBlue": 1, "RobloxSquare": 2,
        "RobloxRound": 3, "ChatGreen": 4, "ChatRed": 5, "DropShadow": 6
    },
    "ScaleType": {"Stretch": 0, "Slice": 1, "Tile": 2, "Fit": 3, "Crop": 4},
    "MeshType": {
        "Head": 0, "Torso": 1, "Wedge": 2, "Sphere": 3, "Cylinder": 4,
        "FileMesh": 5, "Brick": 6, "Prism": 7, "Pyramid": 8,
        "ParallelRamp": 9, "RightAngleRamp": 10, "CornerWedge": 11
    },
    "Style": {"AlternatingSupports": 0, "BridgeStyleSupports": 1, "NoSupports": 2},
    "RenderFidelity": {"Automatic": 0, "Precise": 1},
    "CollisionFidelity": {
        "Default": 0, "Box": 1, "Hull": 2, "PreciseConvexDecomposition": 3
    },
    "Shape": {"Ball": 0, "Block": 1, "Cylinder": 2, "Wedge": 3}
}

content_props = [
    "MeshId", "TextureId", "TextureID", "SoundId",
    "FaceId", "Image", "Decal", "Object", "Source", "StringValue"
]

ref_count = 0
terrain_count = 0
skipped_list = []

def esc(s):
    s = str(s)
    s = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', '', s)
    return escape(s, entities={"'": "&apos;", '"': "&quot;"})

def is_int(n):
    return isinstance(n, int) and not isinstance(n, bool)

def to_num(n):
    try:
        v = float(n)
        if v != v or v == float('inf') or v == float('-inf'):
            return 0.0
        return v
    except:
        return 0.0

def color_hex(r, g, b):
    r = max(0, min(255, round(to_num(r) * 255)))
    g = max(0, min(255, round(to_num(g) * 255)))
    b = max(0, min(255, round(to_num(b) * 255)))
    return f"#{r:02x}{g:02x}{b:02x}"

def write_prop(name, val, lines):
    if val is None:
        return
    n = esc(name)

    if isinstance(val, str):
        if name in content_props:
            if val == "":
                cv = "<null></null>"
            elif val.startswith("rbxassetid://") or val.startswith("http"):
                cv = f"<url>{esc(val)}</url>"
            else:
                cv = esc(val)
            lines.append(f'<Content name="{n}">{cv}</Content>\n')
        else:
            lines.append(f'<string name="{n}">{esc(val)}</string>\n')
        return

    if isinstance(val, bool):
        lines.append(f'<bool name="{n}">{str(val).lower()}</bool>\n')
        return

    if isinstance(val, (int, float)):
        v = to_num(val)
        typ = "int" if is_int(v) else "float"
        lines.append(f'<{typ} name="{n}">{v}</{typ}>\n')
        return

    if isinstance(val, list):
        if not val:
            return
        tag = val[0]
        rest = val[1:]
        nums = []
        for x in rest:
            nums.append(x if isinstance(x, str) else to_num(x))

        if tag == "V3" and len(nums) >= 3:
            lines.append(f'<Vector3 name="{n}"><X>{nums[0]}</X><Y>{nums[1]}</Y><Z>{nums[2]}</Z></Vector3>\n')
            return
        if tag == "V2" and len(nums) >= 2:
            if nums[0] == 0 and nums[1] == 0:
                return
            lines.append(f'<Vector2 name="{n}"><X>{nums[0]}</X><Y>{nums[1]}</Y></Vector2>\n')
            return
        if tag == "C3" and len(nums) >= 3:
            lines.append(f'<Color3 name="{n}"><R>{nums[0]}</R><G>{nums[1]}</G><B>{nums[2]}</B></Color3>\n')
            return
        if tag == "UD2" and len(nums) >= 4:
            lines.append(f'<UDim2 name="{n}"><X><Scale>{nums[0]}</Scale><Offset>{nums[1]}</Offset></X><Y><Scale>{nums[2]}</Scale><Offset>{nums[3]}</Offset></Y></UDim2>\n')
            return
        if tag == "UD" and len(nums) >= 2:
            lines.append(f'<UDim name="{n}"><Scale>{nums[0]}</Scale><Offset>{nums[1]}</Offset></UDim>\n')
            return
        if tag == "NR" and len(nums) >= 2:
            lines.append(f'<NumberRange name="{n}"><Min>{nums[0]}</Min><Max>{nums[1]}</Max></NumberRange>\n')
            return
        if tag == "BC" and len(nums) >= 1:
            lines.append(f'<BrickColor name="{n}">{nums[0]}</BrickColor>\n')
            return
        if tag == "EN" and len(nums) >= 2:
            table = enum_tables.get(nums[0])
            if table is None:
                skipped_list.append(f"{name} (Enum.{nums[0]}.*)")
                return
            enum_id = table.get(nums[1])
            if enum_id is None:
                skipped_list.append(f"{name} (Enum.{nums[0]}.{nums[1]})")
                return
            lines.append(f'<token name="{n}">{enum_id}</token>\n')
            return
        if tag == "V3I" and len(nums) >= 3:
            lines.append(f'<Vector3int16 name="{n}"><X>{nums[0]}</X><Y>{nums[1]}</Y><Z>{nums[2]}</Z></Vector3int16>\n')
            return
        if tag == "V2I" and len(nums) >= 2:
            lines.append(f'<Vector2int16 name="{n}"><X>{nums[0]}</X><Y>{nums[1]}</Y></Vector2int16>\n')
            return
        if tag == "PP" and len(nums) >= 5:
            lines.append(f'<PhysicalProperties name="{n}"><Density>{nums[0]}</Density><Friction>{nums[1]}</Friction><Elasticity>{nums[2]}</Elasticity><FrictionWeight>{nums[3]}</FrictionWeight><ElasticityWeight>{nums[4]}</ElasticityWeight></PhysicalProperties>\n')
            return
        if tag == "CF" and len(nums) >= 9:
            px, py, pz = nums[0], nums[1], nums[2]
            lx, ly, lz = nums[3], nums[4], nums[5]
            ux, uy, uz = nums[6], nums[7], nums[8]
            rx = ly * uz - lz * uy
            ry = lz * ux - lx * uz
            rz = lx * uy - ly * ux
            lines.append(f'<CoordinateFrame name="{n}"><X>{px}</X><Y>{py}</Y><Z>{pz}</Z><R00>{rx}</R00><R01>{ux}</R01><R02>{-lx}</R02><R10>{ry}</R10><R11>{uy}</R11><R12>{-ly}</R12><R20>{rz}</R20><R21>{uz}</R21><R22>{-lz}</R22></CoordinateFrame>\n')
            return
        if tag == "NS":
            lines.append(f'<NumberSequence name="{n}">')
            for kp in rest:
                if isinstance(kp, list) and len(kp) >= 3:
                    lines.append(f'<NumberSequenceKeypoint time="{kp[0]}" value="{kp[1]}" envelope="{kp[2]}"/>')
            lines.append('</NumberSequence>\n')
            return
        if tag == "CS":
            lines.append(f'<ColorSequence name="{n}">')
            for kp in rest:
                if isinstance(kp, list) and len(kp) >= 4:
                    tm = to_num(kp[0])
                    hexc = color_hex(kp[1], kp[2], kp[3])
                    lines.append(f'<ColorSequenceKeypoint time="{tm}" value="{hexc}"/>')
            lines.append('</ColorSequence>\n')
            return

    lines.append(f'<string name="{n}">{esc(json.dumps(val))}</string>\n')

def build_instance(item, parent_ref, lines):
    global ref_count, terrain_count
    cls = item.get("Class", "Folder")
    if cls == "Terrain":
        terrain_count += 1
        return
    name = item.get("Name", "Instance")
    props = item.get("Properties", {})
    children = item.get("Children", [])
    attrs = item.get("Attributes", {})
    ref = "RBX" + str(ref_count)
    ref_count += 1

    if props.get("MeshId") and not (props.get("MeshType") and isinstance(props["MeshType"], list) and
                                     props["MeshType"][0] == "EN" and
                                     props["MeshType"][1] == "MeshType" and
                                     props["MeshType"][2] == "FileMesh"):
        props["MeshType"] = ["EN", "MeshType", "FileMesh"]

    if cls == "MeshPart" and props.get("MeshId"):
        size = None
        if props.get("Size") and isinstance(props["Size"], list) and props["Size"][0] == "V3":
            size = props["Size"][:]
        elif props.get("size") and isinstance(props["size"], list) and props["size"][0] == "V3":
            size = props["size"][:]
        else:
            size = ["V3", 1, 1, 1]
        props["size"] = size[:]
        props["InitialSize"] = size[:]

    lines.append(f'\t<Item class="{esc(cls)}" referent="{ref}">')
    lines.append('\t\t<Properties>')
    lines.append(f'\t\t\t<string name="Name">{esc(name)}</string>')

    for k, v in props.items():
        tmp = []
        write_prop(k, v, tmp)
        if tmp:
            lines.append('\t\t\t' + ''.join(tmp).strip())

    for k, v in attrs.items():
        tmp = []
        write_prop(k, v, tmp)
        if tmp:
            lines.append('\t\t\t' + ''.join(tmp).strip())

    if parent_ref:
        lines.append(f'\t\t\t<Ref name="Parent">{parent_ref}</Ref>')

    lines.append('\t\t</Properties>')

    for child in children:
        build_instance(child, ref, lines)

    lines.append('\t</Item>')

def convert(data):
    global ref_count, terrain_count, skipped_list
    ref_count = 0
    terrain_count = 0
    skipped_list = []

    if not isinstance(data, list):
        raise ValueError("JSON must be an array of objects.")

    lines = []
    lines.append('<?xml version="1.0" encoding="UTF-8"?>')
    lines.append('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')
    lines.append('\t<Meta name="ExplicitAutoJoints">true</Meta>')
    lines.append('\t<External>null</External>')
    lines.append('\t<External>nil</External>')

    root_ref = "RBX" + str(ref_count)
    ref_count += 1
    lines.append(f'\t<Item class="Model" referent="{root_ref}">')
    lines.append('\t\t<Properties>')
    lines.append('\t\t\t<string name="Name">WorkspaceMap</string>')
    lines.append('\t\t</Properties>')

    for idx, item in enumerate(data):
        build_instance(item, root_ref, lines)
        if (idx + 1) % 2000 == 0:
            sys.stderr.write(f"progress: {round((idx+1)/len(data)*100)}%\n")

    lines.append('\t</Item>')
    lines.append('\t<SharedStrings>')
    lines.append('\t</SharedStrings>')
    lines.append('</roblox>')

    return {
        "xml": '\n'.join(lines),
        "count": len(data),
        "terrain_skipped": terrain_count,
        "skipped": skipped_list
    }

def main():
    if len(sys.argv) >= 2:
        infile = sys.argv[1]
        with open(infile, 'r', encoding='utf-8') as f:
            txt = f.read()
    else:
        txt = sys.stdin.read()

    data = json.loads(txt)
    result = convert(data)

    if len(sys.argv) >= 3:
        outfile = sys.argv[2]
        with open(outfile, 'w', encoding='utf-8') as f:
            f.write(result["xml"])
    else:
        sys.stdout.write(result["xml"])

    if result["terrain_skipped"]:
        sys.stderr.write(f"Terrain skipped: {result['terrain_skipped']}\n")
    if result["skipped"]:
        sys.stderr.write(f"Skipped properties (unknown enum): {len(result['skipped'])}\n")
        sys.stderr.write(", ".join(result["skipped"][:10]) + ("..." if len(result["skipped"]) > 10 else "") + "\n")

if __name__ == "__main__":
    main()