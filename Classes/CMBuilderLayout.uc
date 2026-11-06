// A saved Builder layout: the mesh pieces standing on one map, saved by an admin (savelayout) and built again with
// loadlayout, and at every round start with bRebuildLayoutEachRound. Kept in ROMutCMenu_Layouts.ini on the server, one
// section per layout, named after the map and the layout.
class CMBuilderLayout extends Object
    config(MutCMenu_Layouts)
    perobjectconfig;

var config string MapName;          // the map it was saved on
var config string LayoutName;       // its name, as the admin typed it
var config string SavedBy;
var config array<string> Pieces;    // one per piece: mesh|x,y,z|pitch,yaw,roll|scale x,y,z|health|team

const MAX_LAYOUT_PIECES = 400;
const SECTION_PREFIX = "L_";

// Letters and digits kept, anything else made an underscore: the name of the layout's section in the ini
static function string SafeName(string S)
{
    local string Out, C;
    local int i, A;

    for (i = 0; i < Len(S); i++)
    {
        C = Mid(S, i, 1);
        A = Asc(C);
        if ((A >= 48 && A <= 57) || (A >= 65 && A <= 90) || (A >= 97 && A <= 122))
            Out $= C;
        else
            Out $= "_";
    }
    return Out;
}

static function string MapPrefix(string Map)
{
    return SECTION_PREFIX $ SafeName(Map) $ "__";
}

// The layout called Layout on Map, read from the ini (empty when there is none)
static function CMBuilderLayout Open(string Map, string Layout)
{
    return new(None, MapPrefix(Map) $ SafeName(Caps(Layout))) class'CMBuilderLayout';
}

// The names of the layouts saved for Map, with how many pieces each has
static function GetLayouts(string Map, out array<string> Names, out array<int> Counts)
{
    local array<string> Sections;
    local CMBuilderLayout L;
    local string ObjName;
    local int i, Space;

    Names.Length = 0;
    Counts.Length = 0;
    GetPerObjectConfigSections(class'CMBuilderLayout', Sections);
    for (i = 0; i < Sections.Length; i++)
    {
        Space = InStr(Sections[i], " ");
        ObjName = (Space != -1) ? Left(Sections[i], Space) : Sections[i];
        if (Left(ObjName, Len(MapPrefix(Map))) != MapPrefix(Map))
            continue;
        L = new(None, ObjName) class'CMBuilderLayout';
        if (L.Pieces.Length == 0 || L.LayoutName == "")
            continue;
        Names.AddItem(L.LayoutName);
        Counts.AddItem(L.Pieces.Length);
    }
}

static function string VectorText(vector V)
{
    return V.X $ "," $ V.Y $ "," $ V.Z;
}

static function vector ParseVector(string S)
{
    local array<string> P;
    local vector V;

    P = SplitString(S, ",", false);
    if (P.Length >= 3)
    {
        V.X = float(P[0]);
        V.Y = float(P[1]);
        V.Z = float(P[2]);
    }
    return V;
}

// A piece as one line
static function string PieceText(CMAStaticMesh P)
{
    return P.ReplicatedMeshPath $ "|" $ VectorText(P.Location) $ "|" $ P.Rotation.Pitch $ "," $ P.Rotation.Yaw $ "," $ P.Rotation.Roll
        $ "|" $ VectorText(P.StaticMeshComponent.Scale3D) $ "|" $ P.StartHealth $ "|" $ P.BuiltByTeam;
}

// A line back into its parts; false when it isn't one
static function bool ParsePiece(string Line, out string Mesh, out vector Loc, out rotator Rot, out vector Scale, out int Health, out byte Team)
{
    local array<string> F;
    local vector R;

    F = SplitString(Line, "|", false);
    if (F.Length < 6 || F[0] == "")
        return false;
    Mesh = F[0];
    Loc = ParseVector(F[1]);
    R = ParseVector(F[2]);
    Rot.Pitch = int(R.X);
    Rot.Yaw = int(R.Y);
    Rot.Roll = int(R.Z);
    Scale = ParseVector(F[3]);
    Health = int(F[4]);
    Team = byte(int(F[5]));
    return true;
}
