function show_gnd_truth_img(obj, frame)
gtMasks = obj.load_gnd_truth(frame);
obj.show_detection_img(frame, gtMasks, 2);
