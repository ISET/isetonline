import React from 'react'
import Image from "react-bootstrap/Image";
import Stack from "react-bootstrap/Stack";

const ImageRenderer = (props) => {
  return (
    <Stack direction="horizontal" className="h-100">
      <Image rounded src={props.getValue()} className="h-auto w-100" />
    </Stack>
  );
};

export default ImageRenderer;