
// RENDER SELECTION
part_to_render = "Assembly"; // [Assembly,Animated_Assembly, Palm, Finger_Assembly, Thumb_Assembly, Finger_Proximal, Finger_Mid, Finger_Distal, Thumb_Proximal, Thumb_Mid, Thumb_Distal]
//GLOBAL SETTING
$fn = 60; 

//DIMENSIONS
bolt_dia = 3.2;       
nut_width = 5.8;      
nut_thick = 3.0;
tolerance = 0.5;      

finger_w = 18;        
finger_h = 16;        
finger_spacing = 22;  // Distance between finger centers

knuckle_ear_th = 4.0; 
palm_thick = 20;      
palm_w = 90;
palm_len = 80;

// Joint Geometry
tongue_w = finger_w / 2; 
prong_w = (finger_w - tongue_w) / 2; 


//1. UTILITY MODULES


module rounded_box(dim, r) {
    hull() {
        translate([r, r, r]) sphere(r=r);
        translate([dim[0]-r, r, r]) sphere(r=r);
        translate([dim[0]-r, dim[1]-r, r]) sphere(r=r);
        translate([r, dim[1]-r, r]) sphere(r=r);
        
        translate([r, r, dim[2]-r]) sphere(r=r);
        translate([dim[0]-r, r, dim[2]-r]) sphere(r=r);
        translate([dim[0]-r, dim[1]-r, dim[2]-r]) sphere(r=r);
        translate([r, dim[1]-r, dim[2]-r]) sphere(r=r);
    }
}

module nut_trap_shape() {
    rotate([90, 0, 0]) 
    cylinder(h=tongue_w, d=nut_width / cos(30) + 0.2, $fn=6, center=true);
}

module bolt_hole(len=50) {
    rotate([90, 0, 0]) 
    cylinder(h=len, d=bolt_dia, center=true); 
}

// Creates a smooth entry/exit for tendons to prevent string fraying
module tendon_channel(len, offset_z) {
    translate([0, 0, offset_z]) {
        rotate([0,90,0]) {
            // Main channel
            cylinder(h=len*3, d=2, center=true);
            // Flares at ends (conical smooth entry)
            translate([0, 0, len/2]) cylinder(h=4, d1=2, d2=4, center=true);
            translate([0, 0, -len/2]) rotate([180,0,0]) cylinder(h=4, d1=2, d2=4, center=true);
        }
    }
}


//2. FINGER MODULE

module organic_hull(len, start_d, end_d, w_factor) {
    hull() {
        translate([0,0,0]) scale([1, w_factor, 1]) sphere(d=start_d);
        translate([len,0,0]) scale([1, w_factor, 1]) sphere(d=end_d);
    }
}

module phalanx(len, type="mid") {
    w_scale = finger_w / finger_h; 
    
    difference() {
        union() {
            // Main Body
            if (type == "distal") {
                hull() {
                    translate([0,0,0]) scale([1, w_scale, 1]) sphere(d=finger_h);
                    translate([len,0,0]) scale([1, w_scale*0.9, 0.8]) sphere(d=finger_h);
                }
            } else {
                organic_hull(len, finger_h, finger_h*0.85, w_scale);
            }

            // Mechanical Stop (Prevents backward bending)
            // Adds a small ridge on the top-rear
            if (type != "proximal") {
                translate([0, 0, finger_h/2 - 2])
                    cube([4, finger_w-2, 4], center=true);
            }
        }
        
        // Pivot Hole
        translate([0,0,0]) bolt_hole();
        
        // Distal Connection (Tongue)
        if (type != "distal") {
            translate([len, 0, 0]) {
                 // Cutout for next finger segment
                 cube([finger_h, finger_w/2.8, finger_h*1.5], center=true);
                 bolt_hole(); 
            }
        }
        
        // Proximal Connection (Groove)
        if (type != "proximal") {
            difference() {
                // Outer Cut (Shape the knuckle)
                cube([finger_h, finger_w+2, finger_h+2], center=true);
                // Inner Keep (The prongs)
                cube([finger_h+2, finger_w/2.8 - tolerance, finger_h+2], center=true);
            }
        }
        
        //TENDON CHANNELS
        // Top (Extension) - Flared
        tendon_channel(len, -finger_h/2 + 2);
        
        // Bottom (Flexion) - Flared
        tendon_channel(len, finger_h/2 - 2);
        
        // Rotation Clearance (Rounder cut for smooth movement)
        translate([-1, 0, -finger_h/2 - 3]) 
            rotate([0, 45, 0])
            cube([6, 20, 8], center=true);
            
        // Extension Stop Clearance (Front)
        if (type != "distal") {
             translate([len+2, 0, finger_h/2 - 2])
                cube([4, finger_w, 5], center=true);
        }
    }
}

module finger_assembly(lengths=[40, 30, 25], current_flex=0) {
    // Proximal Phalanx
    rotate([0, current_flex, 0]) { 
        phalanx(lengths[0], "proximal");
        
        // Mid Phalanx (Chained transform)
        translate([lengths[0], 0, 0]) 
        rotate([0, current_flex, 0]) {
            phalanx(lengths[1], "mid");
            
            // Distal Phalanx (Chained transform)
            translate([lengths[1], 0, 0]) 
            rotate([0, current_flex, 0]) {
                phalanx(lengths[2], "distal");
            }
        }
    }
}

//3. PALM MODULE
module knuckle_mount() {
    lip_z = finger_h/2 + 3.5; 
    
    difference() {
        union() {
            // 1. Central Tongue
            rotate([90, 0, 0]) 
                cylinder(h=tongue_w, d=finger_h, center=true);
            
            // 2. Connection to Palm (Reinforced)
            hull() {
                translate([-6, 0, 0])
                    cube([12, tongue_w, finger_h], center=true);
                translate([-15, 0, 0]) 
                    cube([5, finger_w, 15], center=true);
            }

            // 3. Integrated Roof (Knuckle cover)
            hull() {
                translate([6, 0, lip_z]) 
                    cube([1, finger_w, 2], center=true); 
                translate([-5, 0, lip_z + 1]) 
                    cube([2, finger_w, 2], center=true);
                translate([-15, 0, 0]) 
                    cube([5, finger_w, 15], center=true);
            }
        }
        
        // Nut Trap
        nut_trap_shape();
    }
}

module palm_chassis() {
    difference() {
        union() {
            // Main Body
            hull() {
                translate([-palm_len+5, -palm_w*0.4, -palm_thick/2]) 
                    rounded_box([10, palm_w*0.8, palm_thick], 2);
                translate([-5, -palm_w/2, -palm_thick/2.05]) 
                    rounded_box([8, palm_w, palm_thick], 2);
            }
            
            // Thumb Connection Base - REINFORCED
            hull() {
                // Connection at palm
                translate([-palm_len/2.5, palm_w/2 - 5, 0])
                      cube([20, 10, 20], center=true);
                
                // Connection at thumb knuckle
                translate([-palm_len/3, palm_w/2 + 25, 10]) 
                    rotate([0, 30, 45]) 
                    sphere(r=15);
            }
            
            // Webbing (Smoothed)
            hull() {
                 translate([-palm_len/2, palm_w/2 - 5, -palm_thick/2])
                       rounded_box([30, 5, palm_thick], 2);
                 translate([-palm_len/3 - 5, palm_w/2 + 10, 0]) sphere(r=8);
            }

            // Finger Mounts
            for(i=[-1.5 : 1 : 1.5]) {
                translate([0, i*finger_spacing, 0]) knuckle_mount();
            }
        }
        
        //SUBTRACTIVE GEOMETRY
        
        // Finger Joint Holes
        for(i=[-1.5 : 1 : 1.5]) {
            translate([0, i*finger_spacing, 0]) {
                bolt_hole(); 
                
                // Nut Trap specific to mount
                nut_trap_shape();

                // Clearance for finger rotation
                rotate([90, 0, 0]) 
                cylinder(h=finger_w+tolerance*2, d=finger_h+4, center=true); 
            }
        }
        
        // Thumb Joint & Clearance
        translate([-palm_len/3, palm_w/2 + 25, 10]) 
            rotate([0, 30, 45]) {
                bolt_hole();
                nut_trap_shape();
                
                // Rotation Clearance
                rotate([90, 0, 0]) 
                cylinder(h=finger_w+tolerance*2, d=finger_h+4, center=true);
                
                // Range of motion cut
                translate([15, 0, 0])                    
                cube([30, finger_w + 1.0, finger_h + 4.0], center=true);
            }

        // Tendon Channels (Palm)
        // Using hull() between spheres creates smooth internal pipes
        for(i=[-1.5 : 1 : 1.5]) {
            // Flexion
            hull() { 
                translate([0, i*finger_spacing, -finger_h/2 + 2]) sphere(d=2.5); 
                translate([-palm_len-5, i*10, -5]) sphere(d=2.5); 
            }
            // Extension
            hull() { 
                translate([0, i*finger_spacing, finger_h/2 - 2]) sphere(d=2.5); 
                translate([-palm_len-5, i*10, 5]) sphere(d=2.5); 
            }
        }
        
        // Thumb Routing
        hull() {
             translate([-palm_len/3, palm_w/2 + 25, 10]) rotate([0, 30, 45]) translate([-5, 0, -5]) sphere(d=3);
             translate([-palm_len+5, 20, -5]) sphere(d=3);
        }
        hull() {
             translate([-palm_len/3, palm_w/2 + 25, 10]) rotate([0, 30, 45]) translate([-5, 0, 5]) sphere(d=3);
             translate([-palm_len+5, 20, 5]) sphere(d=3);
        }
            
        // Wrist hollow
        translate([-palm_len/1.5, -palm_w/2 + 10, -palm_thick/2 - 5]) 
             rounded_box([20, palm_w-20, palm_thick+10], 2);
    }
}
//4. MAIN SWITCH (VISUALIZATION & EXPORT)

if (part_to_render == "Assembly") {

    // Render Palm
    color("#6A7A89") palm_chassis();

    // Render 4x Fingers (Index to Pinky)
    for(i=[-1.5 : 1 : 1.5]) {
        translate([0, i*finger_spacing, 0]) 
            color("#D9E2E8") 
            finger_assembly([35, 25, 22]); // Standard Finger Lengths
    }

    // Render Thumb
    translate([-palm_len/3, palm_w/2 + 25, 10]) 
        rotate([0, 30, 45]) 
        color("#FF3B3B") 
        finger_assembly([30, 25, 22]); // Shorter Thumb Lengths

}
else if (part_to_render == "Animated_Assembly") {
    

    animation_angle = 10 + (sin($t * 360) + 1) * 35; 

    color("#6A7A89") palm_chassis();

    // Render 4x Fingers
    for(i=[-1.5 : 1 : 1.5]) {
        translate([0, i*finger_spacing, 0]) 
            color("#D9E2E8") 
            // Pass the animation angle to the finger
            finger_assembly([35, 25, 22], animation_angle); 
    }

    // Render Thumb (Offsets modified for correct rotation axis)
    translate([-palm_len/3, palm_w/2 + 25, 10]) 
        rotate([0, 30, 45]) 
        color("#FF3B3B") 
        finger_assembly([30, 25, 22], animation_angle * 0.8); 
} else if (part_to_render == "Palm") {
    color("#6A7A89")
    palm_chassis();

//VISUALIZATION ASSEMBLIES

} else if (part_to_render == "Finger_Assembly") {
    // Visualizes a complete standard finger (35-25-22)
    color("#556B2F") 
    finger_assembly([35, 25, 22]); 

} else if (part_to_render == "Thumb_Assembly") {
    // Visualizes the complete thumb (30-25-22)
    color("#6A7A89") 
    finger_assembly([30, 25, 22]);

//PRINT PARTS (Oriented flat for strength)

// STANDARD FINGERS (Print 4 Sets)
} else if (part_to_render == "Finger_Proximal") {
    rotate([0, -90, 0]) phalanx(35, "proximal");
    
} else if (part_to_render == "Finger_Mid") {
    rotate([0, -90, 0]) phalanx(25, "mid");
    
} else if (part_to_render == "Finger_Distal") {
    rotate([0, -90, 0]) phalanx(22, "distal");

// THUMB PARTS (Print 1 Set)
} else if (part_to_render == "Thumb_Proximal") {
    rotate([0, -90, 0]) phalanx(30, "proximal"); // Shorter (30mm)
    
} else if (part_to_render == "Thumb_Mid") {
    rotate([0, -90, 0]) phalanx(25, "mid");      // Same as finger
    
} else if (part_to_render == "Thumb_Distal") {
    rotate([0, -90, 0]) phalanx(22, "distal");   // Same as finger
}
