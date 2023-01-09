
class CMVehicle_T26_ActualContent extends WWVehicle_T26_ActualContent; //MutCMenuTB.CMVehicle_T26_ActualContent

var array<Actor> CldActors;

simulated event PreBeginPlay()
{
    super.PreBeginPlay();

   settimer(5, true, 'ResetActorCollision');
}

simulated event tick(float DeltaTime)
{
    local Actor TracedActor;

    super.tick(DeltaTime);

    //ViewDirection = Vector(GetViewRotation());
    //EndTrace = Location + ViewDirection * CylinderComponent.CollisionRadius;

    if (bDriving)
    {
        foreach CollidingActors(class'Actor', TracedActor, 500)
	    {
            //`log(EndTrace);

	    	if(!TracedActor.IsA('Terrain') && CldActors.Find(TracedActor) == -1 && !ClassIsChildOf(TracedActor.class, class'Pawn'))
            {
                `log("Ghosting:"@TracedActor);
                CldActors.AddItem(TracedActor);
                // TracedActor.SetCollision(false, false);
                // TracedActor.SetCollisionType(COLLIDE_NoCollision);
                TracedActor.CollisionComponent.SetBlockRigidBody(false);
                //TracedActor.CollisionComponent.SetRBCollidesWithChannel(RBCC_Vehicle, false);
            }
	    }   
    }
}

function ResetActorCollision()
{
    local Actor ActorToDo, TracedActor;

    foreach CldActors(ActorToDo)
    {
        foreach CollidingActors(class'Actor', TracedActor, 600)
	    {
            if(TracedActor == ActorToDo)
            {
                `log("Still colliding:"@ActorToDo);
                CldActors.RemoveItem(ActorToDo);
            }   
        } 
    }
    foreach CldActors(ActorToDo)
    {
        `log("ReColliding:"@ActorToDo);
        // ActorToDo.SetCollision(true, true);
        // ActorToDo.SetCollisionType(COLLIDE_BlockAll);
        ActorToDo.CollisionComponent.SetBlockRigidBody(true);
        //ActorToDo.CollisionComponent.SetRBCollidesWithChannel(RBCC_Vehicle, true);
        CldActors.RemoveItem(ActorToDo);
    }
}

/* defaultproperties
{
    Begin Object Name=ROSVehicleMesh
		RBCollideWithChannels=(GameplayPhysics=TRUE,EffectPhysics=TRUE,Vehicle=TRUE)
	End Object
} */