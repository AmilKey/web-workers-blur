#self. or this. For Opera and FF, spent on it for 2 hours
self.onmessage = (event) ->
  
  getPixel = (x, y) ->
    x = 0  if x < 0
    y = 0  if y < 0
    x = width - 1  if x >= width
    y = height_end - 1  if y >= height_end
    index = (y * width + x) * 4
    [
      imagedata_work.data[index + 0]
      imagedata_work.data[index + 1]
      imagedata_work.data[index + 2]
      imagedata_work.data[index + 3]
    ]

  setPixel = (x, y, r, g, b, a) ->
    y = y - radius
    index = (y * width + x) * 4
    imagedata_result.data[index + 0] = r
    imagedata_result.data[index + 1] = g
    imagedata_result.data[index + 2] = b
    imagedata_result.data[index + 3] = a
    return

  imagedata_work = event.data.imagedata_work
  imagedata_result = event.data.imagedata_result
  width = event.data.width
  height_end = event.data.height_end
  radius = event.data.radius
  number = event.data.number
  sum_r = undefined
  sum_g = undefined
  sum_b = undefined
  sum_a = undefined
  scale = (radius * 2 + 1) * (radius * 2 + 1)
  # Количество пикселей, попадающих в радиус размывания
  num_pixels = width * ( height_end - radius )
  lastprogress = 0
  y = radius - 1
  while y < height_end - radius
    x = 0
    while x < width
      progress = Math.round(((((y+1) * width) + height_end - radius) / num_pixels) * 100)
      if progress > lastprogress
        lastprogress = progress
        postMessage
          status: "progress"
          progress: progress
          number: number

      sum_r = 0
      sum_g = 0
      sum_b = 0
      sum_a = 0
      dy = -radius

      while dy <= radius
        dx = -radius

        while dx <= radius
          pixeldata = getPixel(x + dx, y + dy)
          sum_r += pixeldata[0]
          sum_g += pixeldata[1]
          sum_b += pixeldata[2]
          sum_a += pixeldata[3]
          dx++
        dy++
      
      # Получение исходящего цвета (деление суммы цветов на количество 
      # пикселей в радиусе размывания
      setPixel x, y, Math.round(sum_r / scale), Math.round(sum_g / scale), Math.round(sum_b / scale), Math.round(sum_a / scale)
      x++
    y++

  #отправляем полученный результат
  postMessage
    status: "complite"
    imagedata: imagedata_result
    number: number

  #прекращаем работу объекта Worker
  self.close() 
  return
