// A C++ program to check if a given Vector2D lies inside a given polygon
// Refer https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/
// for explanation of functions onSegment(), orientation() and doIntersect()
class CMAObjective extends ROObjective;

const INF = 100000;
var array<Vector2D> Corners;
var ROGameInfoTerritories ROGIT;
var ROGameReplicationInfo ROGRI;
var bool bSpawnedOBJ;

function Init(array<vector2d> InCorners)
{
    local vector2d Cornerp;
    local int i, i2;

    Corners = InCorners;
    bSpawnedOBJ = true;

    ROGIT = ROGameInfoTerritories(WorldInfo.Game);
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
/*     for(i = 0; i < ROGIT.Objectives.Length; I++)
    {
        if (ROGIT.Objectives[i].ObjIndex >= i2)
        {
            i2 = ROGIT.Objectives[i].ObjIndex + 1;
        }
    }
     */
    for(i = 0; i < ROGIT.Objectives.Length; I++)
    {
        if (ROGIT.Objectives[i].ObjRepIndex >= i2)
        {
            i2 = ROGIT.Objectives[i].ObjRepIndex + 1;
        }
    }
    ObjIndex = i2;
    ObjRepIndex = i2;
    ObjShortName = IntToString(i2);
    MinimumCaptureTime = 30;

    ROGRI.AddObjective(Self, True);
    CMGameReplicationInfo(ROGRI).NewObj = Self;

    ROGIT.Objectives.AddItem(self);
    Reset();
	SetEnabled(true);
	SetActive(true);

    foreach InCorners(CornerP)
    {
        `log(self$": My Corners are - "$CornerP.x@cornerp.y);
    }
}

function bool CheckForPlayers(vector PlayerLoc)
{
    local vector2d P;

    p.x = PlayerLoc.X;
    p.y = PlayerLoc.y;

    return isInside(Corners, Corners.Length, p);
}

// Given three collinear Vector2Ds p, q, r, the function checks if
// Vector2D q lies on line segment 'pr'
function bool onSegment(Vector2D p, Vector2D q, Vector2D r)
{
    if (q.x <= max(p.x, r.x) && q.x >= min(p.x, r.x) &&
            q.y <= max(p.y, r.y) && q.y >= min(p.y, r.y))
        return true;
    else
        return false;
}
 
// To find orientation of ordered triplet (p, q, r).
// The function returns following values
// 0 --> p, q and r are collinear
// 1 --> Clockwise
// 2 --> Counterclockwise
function int orientation(Vector2D p, Vector2D q, Vector2D r)
{
    local int val;
    val = (q.y - p.y) * (r.x - q.x) -
            (q.x - p.x) * (r.y - q.y);
 
    if (val == 0) return 0; // collinear
    return (val > 0)? 1: 2; // clock or counterclock wise
}
 
// The function that returns true if line segment 'p1q1'
// and 'p2q2' intersect.
function bool doIntersect(Vector2D p1, Vector2D q1, Vector2D p2, Vector2D q2)
{
    local int o1, o2, o3, o4;
    // Find the four orientations needed for general and
    // special cases
    o1 = orientation(p1, q1, p2);
    o2 = orientation(p1, q1, q2);
    o3 = orientation(p2, q2, p1);
    o4 = orientation(p2, q2, q1);
 
    // General case
    if (o1 != o2 && o3 != o4)
        return true;
 
    // Special Cases
    // p1, q1 and p2 are collinear and p2 lies on segment p1q1
    if (o1 == 0 && onSegment(p1, p2, q1)) return true;
 
    // p1, q1 and p2 are collinear and q2 lies on segment p1q1
    if (o2 == 0 && onSegment(p1, q2, q1)) return true;
 
    // p2, q2 and p1 are collinear and p1 lies on segment p2q2
    if (o3 == 0 && onSegment(p2, p1, q2)) return true;
 
    // p2, q2 and q1 are collinear and q1 lies on segment p2q2
    if (o4 == 0 && onSegment(p2, q1, q2)) return true;
 
    return false; // Doesn't fall in any of the above cases
}
 
// Returns true if the Vector2D p lies inside the polygon[] with n vertices
function bool isInside(array<Vector2D> polygon, int n, Vector2D p)
{
    local Vector2D extreme;
    local int decrease, count, i, next;
    // There must be at least 3 vertices in polygon[]
    if (n < 3) return false;
 
    // Create a point for line segment from p to infinite
    extreme.x = INF;
    extreme.y = p.y;
   
    // To count number of points in polygon
    // whose y-coordinate is equal to
    // y-coordinate of the point
    decrease = 0;
 
    // Count intersections of the above line with sides of polygon
    count = 0;
    i = 0;
    while (true)
    {
        next = (i+1)%n;
       
          if(polygon[i].y == p.y) decrease++;
 
        // Check if the line segment from 'p' to 'extreme' intersects
        // with the line segment from 'polygon[i]' to 'polygon[next]'
        if (doIntersect(polygon[i], polygon[next], p, extreme))
        {
            // If the point 'p' is collinear with line segment 'i-next',
            // then check if it lies on segment. If it lies, return true,
            // otherwise false
            if (orientation(polygon[i], p, polygon[next]) == 0)
            return onSegment(polygon[i], p, polygon[next]);
 
            count++;
        }
        i = next;

        if (I == 0)
            break;
    }
     
    // Reduce the count by decrease amount
    // as these points would have been added twice
    count -= decrease;
   
    // Return true if count is odd, false otherwise
    return (count % 2 == 1);// Same as (count%2 == 1)
}

function string IntToString(int Int)
{
    switch(Int)
    {
        case 0:
        return "A";

        case 1:
        return "B";

        case 2:
        return "C";

        case 3:
        return "D";

        case 4:
        return "E";

        case 5:
        return "F";

        case 6:
        return "G";

        case 7:
        return "H";

        case 8:
        return "I";

        case 9:
        return "J";

        case 10:
        return "K";

        case 11:
        return "L";

        case 12:
        return "M";

        case 13:
        return "N";

        case 14:
        return "O";

        case 15:
        return "P";
    }
}


defaultproperties
{
    MinimumCaptureTime=30
    InitialObjState=2
    ObjState=2

    ObjVolume=none

    bStatic=false
	bNoDelete=false
}