function imTest = preprocess_image(imTest)

if isa(imTest, 'uint16')
    imTest = uint8(255 * double(imTest) / 55000);
end
if size(imTest, 3) == 1
    imTest = repmat(imTest, [1 1 3]);
end
