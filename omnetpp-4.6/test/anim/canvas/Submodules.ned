module Submodules
{
    parameters:
        @display("bgb=800,500");
        @figure[below](type=rectangle;coords=120,100;size=400,400;fillColor=grey);
        @figure[submodules](type=group);
        @figure[above](type=rectangle;coords=100,150;size=100,300;fillColor=green);
    types:
        module Dummy { @display("t=Text annotation;q=queue;i2=status/noentry;r=100"); }
    submodules:
        dummy1: Dummy { @display("p=200,200"); }
        dummy2: Dummy { @display("p=200,300"); }
}

