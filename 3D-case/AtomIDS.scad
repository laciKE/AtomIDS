rotate([-90,0,0])
difference(){
//Frame
cube([106,105,65], center=true);
// Inside
translate([0,-2,-1.5])
cube([102,104,58], center=true);
// Back hole for Dell Wyse 3040
translate([0,51,-17])
cube([98,5,20], center=true);
// Back hole for TP Link TL-SG105E
translate([0,51,11])
cube([98,5,20], center=true);
// Back hole for TP Link power cord
translate([0,51,24])
cube([5,5,7], center=true);
// Power button hole for Dell Wyse 3040
translate([-39,-41,-29.5])
cylinder(h=6,d=12,$fn=120,center=true);
// Screw holes for IKEA Trotten
translate([0,-15,30])
cylinder(h=8,d=6,$fn=60,center=true);
translate([0,-15,28])
cylinder(h=4,d=12,$fn=60,center=true);
translate([0,17,30])
cylinder(h=8,d=6,$fn=60,center=true);
translate([0,17,28])
cylinder(h=4,d=12,$fn=60,center=true);
// Bottom grid with cooling holes
translate([0,5,-28.5])
import("grid_bottom.stl",center=true);
// Top grid with cooling holes
translate([0,5,30])
import("grid_top.stl",center=true);
// Side grids with cooling holes
translate([55,5,-1.5])
rotate([0,90,0])
import("grid_side.stl",center=true);
translate([-55,5,-1.5])
rotate([0,90,0])
import("grid_side.stl",center=true);
}
