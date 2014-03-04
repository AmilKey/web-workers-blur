custom_parameters = undefined
#выборочные параметры
$('#customParameters').on 'change', ->
  if @checked
    custom_parameters = yes
    $('.form__parameters').fadeIn().height('260px')
  else
    custom_parameters = no
    $('.form__parameters').fadeOut().height 0
  return

# Загрузка изображения
img = new Image()

fileOnload = (e) ->
  img.src = e.target.result
  return

$("#exampleInputFile").change (e) ->
  file = e.target.files[0]
  imageType = /image.*/
  return  unless file.type.match(imageType)
  reader = new FileReader()
  reader.onload = fileOnload
  reader.readAsDataURL file
  return

img.src = 'test.jpg'

###*
  наборы тестов
  count_workers_comp = кол-во потоков для компьютера
  count_workers_mobile = кол-во потоков для мобильных устройств
  radius = радиус размытия
  number_test = номер теста
###
count_workers = count_workers_comp = [ 1, 2, 4, 5, 10, 15, 20, 40, 50, 60, 70, 80, 90 ]
count_workers_mobile = [ 1, 2, 4, 5, 10, 15, 20, 30 ]
radius = '5'
number_test = 0

###
  проверка на мобильное устройство,
  пока чек-бокс, потом можно заменить на автоопределение
###
$('#mobileParameters').on 'change', ->
  if @checked
    count_workers = count_workers_mobile[..]
  else
    count_workers = count_workers_comp[..]
  return

#для статистики
time_workers = []
label_workers = []

#запускаем следующий тест
go = ->
  draw('my_canvas')
  return

draw = (canvas_name) ->
  
  canvas = document.getElementById(canvas_name)
  $('.container__canvas').fadeIn()
  $('.js-info-block').fadeOut()
  ctx = canvas.getContext("2d")
  
  canvas_result = document.getElementById("your_canvas")
  ctx_result = canvas_result.getContext("2d")
  ctx_result.clearRect 0, 0, canvas_result.width, canvas_result.height

  # Рисование изображения
  ctx.clearRect 0, 0, canvas.width, canvas.height
  ctx.drawImage img, 0, 0, img.width, img.height, 0, 0, img.width, img.height
  
  # Поддерживает ли браузер Web Workers?
  if typeof (Worker) isnt "undefined"

    callback = (event) ->
      status = event.data.status
      imagedata = event.data.imagedata
      number = event.data.number
      progress = event.data.progress

      #рисуем часть изображения
      if status is "complite" # Если фильтр выполнил работу
        #считаем кол-во колбеков
        --pending_workers
        unless pending_workers
          result_time = Date.now() - time
          $(".js-total-time").text 'Total Time ' + result_time + 'ms   '
          #запоминаем время и имя потока
          time_workers[number_test] = result_time
          label_workers[number_test] = num_workers + " Web Worker"
          # запускаем функцию с новым кол-вом потоков
          number_test++
          if number_test < count_workers.length and not custom_parameters
            #ждём полсекунды и запускаем новый тест
            setTimeout go, 500
          #после всех тестов строим гистограмму
          else
            chart()
            scroll_to_bottom(700)
         # Переместить принятую Image Data в контекст canvas
        if canvas_result.getContext
          ctx_result.putImageData imagedata, 0, work_height * number
      else
        # Если фильтр не завершил работу, то показываем текущий прогресс
        $(".load_info_" + number).height progress + '%'
        $(".load_info_" + number).text progress + '%'
      return

    workers = []
    num_workers = pending_workers = $("#workers").val() || count_workers[number_test].toString()
    radius = $("#radius").val() || radius

    #очистить содержимое load_info
    $("#load_info").empty()

    #создадим прогрессбары для потоков
    for i in [0...num_workers]
      js_class = "load_info_" + i
      $("#load_info")
        .append ('
        <div class="progress progress-striped active">
          <div class="progress-bar '+ js_class + '" role="progressbar" aria-valuenow="45" aria-valuemin="0" aria-valuemax="100" style="height: 0%">
          </div>
        </div>')

    #ширина для одного прогресс бара
    $(".progress").width ($(".container").width() - num_workers * 5)  / num_workers

    console.time "DEBUG:: TIME create Worker LOOP"
    for i in [0...num_workers]
      workers[i] = new Worker("worker.js") # Создаём новый worker
      workers[i].onmessage = callback
    console.timeEnd "DEBUG:: TIME create Worker LOOP"

    ###*
      Высота для одного Worker'a
      если высота получилась дробная округляем её в большую сторону
    ###
    work_height = Math.ceil canvas.height / num_workers

    ###*
      getImageData - долгая операция, поэтому результат
      лучше хранить в отдельном массиве
    ###
    imagedata_work = []
    imagedata_result = []
    for i in [0...num_workers]
      if i
        imagedata_work[i] = ctx.getImageData 0, work_height * i - radius , canvas.width, work_height + radius
        imagedata_result[i] = ctx.getImageData 0, 0, canvas.width, work_height
      else
        imagedata_work[i] = ctx.getImageData 0, 0, canvas.width, work_height + radius 
        imagedata_result[i] = ctx.getImageData 0, 0, canvas.width, work_height

    time = Date.now()
    console.time "DEBUG:: TIME postMesage LOOP"
    #отправляем данные потокам для расчёта
    for i in [0...num_workers]
      workers[i].postMessage
        # Передача ImageData в worker
        imagedata_work: imagedata_work[i]
        imagedata_result: imagedata_result[i]
        width: canvas.width
        height_end: work_height + 2 * radius
        radius: radius
        number: i
    console.timeEnd "DEBUG:: TIME postMesage LOOP"

  else
    alert "Ваш браузер не поддерживает Web Workers!"
  return

#построение гистограммы
chart = ->
  $("#chart").highcharts
    chart:
      type: "column"
      margin: [ 50, 50, 100, 80]

    title:
      text: "Operation time Web Workers"

    xAxis:
      categories: label_workers
      labels:
        rotation: -45
        align: "right"
        style:
          fontSize: "13px"
          fontFamily: "Verdana, sans-serif"

    yAxis:
      min: 0
      title:
        text: "Time (milliseconds)"

    legend:
      enabled: false

    tooltip:
      pointFormat: "Time: <b>{point.y} milliseconds</b>"

    series: [
      name: "Population"
      data: time_workers
      dataLabels:
        enabled: true
        rotation: -90
        color: "#FFFFFF"
        align: "right"
        x: 4
        y: 10
        style:
          fontSize: "13px"
          fontFamily: "Verdana, sans-serif"
          textShadow: "0 0 3px black"
    ]

  return

#прокрутка вниз страницы
scroll_to_bottom = (speed) ->
  height = $("body").height()
  $("html,body").animate
    scrollTop: height
  , speed
  return