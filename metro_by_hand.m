Gmetro = graph();

nodenumbers = [(1:39)'; (40:85)'; (86:95)'; (96:132)'];

framenumbers = [4000; 7000; 4000; 7000; 4000; 4050; 4060; 4310; 4320; 4420; ...
                4430; 4390; 4380; 4640; 4650; 4650; 4690; 4700; 4700; 4730; ...
                4740; 4780; 4790; 4060; 5400; 5410; 5600; 5610; 5670; 5680; ...
                6330; 6340; 6420; 6430; 6800; 6810; 7000; 7000; 7000; ...
                ...
                7150; 7160; 7200; 7200; 7210; 7210; 7210; 7240; 7250; 7390; 7400; ...
                7440; 7450; 7460; 7470; 7550; 7550; 7560; 7640; 7650; 7730; ...
                7740; 7820; 7830; 7870; 7880; 7980; 7990; 8000; 8010; 8110; ...
                8120; 8170; 8180; 8210; 8220; 8370; 8380; 8360; 8370; 8500; ...
                8500; 8500; 8500; 8500; 8500; ...
                ...
                2790; 2780; 2720; 2710; 2590; 2580; 2500; 2500; 2500; 2500; ...
                ...
                2450; 2440; 2390; 2380; 2250; ...
                2250; [2050; 2040; 2000; 2000]+100; 1990; 1980; 1970; 1960; 1860; ...
                1850; 1840; 1830; 1750; 1740; 1660; 1650; 1590; 1580; 1560; ...
                1550; 1410; 1400; 1340; 1320; 1130; 1120; 1020; 1010; 1000; ...
                1000; 1000];

pathnumbers = [7; 7; 6; 6; 2; 2; 3; 3; 4; 4; ...
               3; 3; 2; 3; 5; 2; 3; 4; 3; 4; ...
               5; 3; 2; 1; 1; 2; 2; 5; 5; 4; ...
               4; 5; 5; 4; 4; 3; 3; 4; 5; ...
               ...
               5; 4; 6; 7; 5.5; 6.5; 8; 4; 5; 8; 7; ...
               6; 6.5; 4; 3; 5; 6.5; 5.5; 5.5; 5; 5; ...
               4; 7; 6; 4; 3; 3; 4; 5; 5.5; 4; ...
               5.5; 5.5; 4; 4; 5; 3; 3.5; 6; 7; ...
               3; 3.5; 4; 5; 5.5; 7; ...
               ...
               2; 1; 1; 2; 2; 1; 1; 2; 6; 7; ...
               ...
               6; 4; 4; 2; 1; ...
               2; 6; 5; 5; 6; 7; 5; 7; 6; 7; ...
               8; 8; 9; 5; 6; 9; 8; 8; 7; 7; ...
               6; 6; 8; 6; 7; 6; 5; 6; 7; 5; ...
               7; 8];

Gmetro = addnode(Gmetro, table(nodenumbers, framenumbers, pathnumbers, 'VariableNames', {'node' 'frame' 'path'}));

edg = [1 2; 3 4; 5 6; 6 7; 6 24; 7 8; 6 13; 8 9; 8 12; 13 12; 9 10; 10 11; 12 11; 11 14; 14 15; 14 16; 14 17; ...
    17 18; 17 19; 18 20; 20 21; 19 22; 22 23; 16 23; 15 21; 23 26; 21 28; 24 25; 25 26; 26 27; 27 28; 28 29; ...
    29 30; 30 31; 31 32; 29 32; 32 33; 33 34; 33 39; 34 35; 35 36; 35 38; 36 37; ...
    ...
    37 54; 38 41; 39 40; 40 41; 41 47; 47 48; 47 53; 53 54; 48 55; 55 57; ...
    4 42; 42 44; 44 57; 42 51; 51 52; ...
    2 43; 43 45; 43 46; 45 52; 43 50; 46 49; 49 50; ...
    52 56; 56 57; ...
    50 62; 62 63; 63 78; 78 79; 62 79; 79 85; ...
    57 58; 58 69; 58 59; 59 60; 60 61; 61 64; 64 65; ...
    54 65; 60 68; 68 69; 65 66; 66 67; 67 70; 70 71; 69 71; ...
    71 72; 72 84; 72 73; 73 74; 74 75; 75 83; 74 82; 66 76; 76 77; 77 81; 76 80; ...
    ...
    1 95; 3 94; 5 86; 86 87; 87 88; 88 89; 86 89; 89 90; 90 91; 91 92; 90 93; ...
    ...
    92 100; 93 99; 99 101; 94 96; 96 97; 97 98; 98 99; 96 102; 102 103; 103 104; 102 105; 95 106; 106 107; ...
    107 114; 114 115; 106 108; 108 109; 109 115; 115 121; 108 110; 110 119; 110 111; 111 112; 112 117; 112 113; ...
    113 116; 116 117; 117 118; 118 119; 119 120; 120 121; 121 122; 122 123; 123 132; 122 124; 124 125; 125 129; ...
    124 126; 126 127; 127 130; 126 128; 128 129; 129 131];

edgeColors = [1; 2; repmat(3, [41 1]); ...
    ...
    repmat(3, [10 1]); repmat(2, [5 1]); repmat(1, [7 1]); 4; 4; repmat(1, [6 1]); repmat(4, [7 1]); ...
    3; 4; 4; 3; 3; 3; 3; repmat(4, [8 1]); repmat(3, [4 1]); ...
    ...
    1; 2; repmat(3, [9 1]); ...
    ...
    3; 3; 3; 2; 3; 3; 3; 2; 2; 2; 2; repmat(1, [32 1])];
edgeColors(edgeColors == 4) = 2;

% w = ones(size(edg, 1), 1);

Gmetro = addedge(Gmetro, edg(:, 1), edg(:, 2), table(edgeColors, 'VariableNames', {'edgeColors'}));

figure(); plot(Gmetro, 'XData', Gmetro.Nodes.path, 'YData', Gmetro.Nodes.frame, 'LineWidth', 2, 'EdgeCData', Gmetro.Edges.edgeColors);
% 'NodeLabel', Gmetro.Nodes.node, 'EdgeLabel', Gmetro.Edges.edgeColors