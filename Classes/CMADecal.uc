class CMADecal extends Actor;

var DecalComponent MyDecal;

DefaultProperties
{
    Begin Object Class=DecalComponent Name=Decal
		bIgnoreOwnerHidden=TRUE // this is needed a the owner of this decal is "hidden" as it is a global entity @see UDecalComponent::IsEnabled()
	End Object
	MyDecal=Decal
}