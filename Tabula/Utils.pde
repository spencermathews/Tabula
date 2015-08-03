static PImage getImageFromMapRequest(WebMapServer wms, GetMapRequest request) {
  BufferedImage mapImage;
  try {
    GetMapResponse response = (GetMapResponse)wms.issueRequest(request);
    if (response == null) return null;
    mapImage = ImageIO.read(response.getInputStream());
  } catch (Exception e) {
    println(e);
    return null;
  }

  return pImageFromBufferedImage(mapImage);
}

static PImage pImageFromBufferedImage(BufferedImage bufferedImage) {
  PImage pImage = new PImage(bufferedImage.getWidth(), bufferedImage.getHeight(), PConstants.ARGB);
  bufferedImage.getRGB(0, 0, pImage.width, pImage.height, pImage.pixels, 0, pImage.width);
  pImage.updatePixels();
  return pImage;
}