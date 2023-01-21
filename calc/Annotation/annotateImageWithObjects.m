function annotatedImage = annotateImageWithObjects(img, objectStruct)
%ANNOTATEIMAGEWITHOBJECTS Draw boxes based on GT type objects
% Currently YOLO annotations are someplace else because they
% have a different format, but they should probably also get put here

annotatedImage = img;
if ~isempty(img) && ~isempty(objectStruct)
    for ii = 1:numel(objectStruct)
        % now build annotated image to return
        annotatedImage = insertObjectAnnotation(annotatedImage,'Rectangle', ...
        cell2mat(objectStruct(ii).bbox2d),objectStruct(ii).label);
    end
end


