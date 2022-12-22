function replace_with_gnd_truth(obj, hgt, gndtruthframes)
for iframe = 1:length(gndtruthframes)
    frame = gndtruthframes(iframe);
    iframe2 = obj.frames == frame;
    obj.masks{iframe2} = hgt.masks{iframe};
    obj.boxes{iframe2} = hgt.boxes{iframe};
    obj.labels{iframe2} = hgt.labels{iframe};
    assert(isempty(obj.labels{iframe2}) || all(~ismember(obj.labels{iframe2}, {'fascicle'})));
    obj.scores{iframe2} = hgt.scores{iframe};
end