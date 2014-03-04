// Generated by CoffeeScript 1.6.3
var chart, count_workers, count_workers_comp, count_workers_mobile, custom_parameters, draw, fileOnload, go, img, label_workers, number_test, radius, scroll_to_bottom, time_workers;

custom_parameters = void 0;

$('#customParameters').on('change', function() {
  if (this.checked) {
    custom_parameters = true;
    $('.form__parameters').fadeIn().height('260px');
  } else {
    custom_parameters = false;
    $('.form__parameters').fadeOut().height(0);
  }
});

img = new Image();

fileOnload = function(e) {
  img.src = e.target.result;
};

$("#exampleInputFile").change(function(e) {
  var file, imageType, reader;
  file = e.target.files[0];
  imageType = /image.*/;
  if (!file.type.match(imageType)) {
    return;
  }
  reader = new FileReader();
  reader.onload = fileOnload;
  reader.readAsDataURL(file);
});

img.src = 'test.jpg';

/**
  наборы тестов
  count_workers_comp = кол-во потоков для компьютера
  count_workers_mobile = кол-во потоков для мобильных устройств
  radius = радиус размытия
  number_test = номер теста
*/


count_workers = count_workers_comp = [1, 2, 4, 5, 10, 15, 20, 40, 50, 60, 70, 80, 90];

count_workers_mobile = [1, 2, 4, 5, 10, 15, 20, 30];

radius = '5';

number_test = 0;

/*
  проверка на мобильное устройство,
  пока чек-бокс, потом можно заменить на автоопределение
*/


$('#mobileParameters').on('change', function() {
  if (this.checked) {
    count_workers = count_workers_mobile.slice(0);
  } else {
    count_workers = count_workers_comp.slice(0);
  }
});

time_workers = [];

label_workers = [];

go = function() {
  draw('my_canvas');
};

draw = function(canvas_name) {
  var callback, canvas, canvas_result, ctx, ctx_result, i, imagedata_result, imagedata_work, js_class, num_workers, pending_workers, time, work_height, workers, _i, _j, _k, _l;
  canvas = document.getElementById(canvas_name);
  $('.container__canvas').fadeIn();
  $('.js-info-block').fadeOut();
  ctx = canvas.getContext("2d");
  canvas_result = document.getElementById("your_canvas");
  ctx_result = canvas_result.getContext("2d");
  ctx_result.clearRect(0, 0, canvas_result.width, canvas_result.height);
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
  if (typeof Worker !== "undefined") {
    callback = function(event) {
      var imagedata, number, progress, result_time, status;
      status = event.data.status;
      imagedata = event.data.imagedata;
      number = event.data.number;
      progress = event.data.progress;
      if (status === "complite") {
        --pending_workers;
        if (!pending_workers) {
          result_time = Date.now() - time;
          $(".js-total-time").text('Total Time ' + result_time + 'ms   ');
          time_workers[number_test] = result_time;
          label_workers[number_test] = num_workers + " Web Worker";
          number_test++;
          if (number_test < count_workers.length && !custom_parameters) {
            setTimeout(go, 500);
          } else {
            chart();
            scroll_to_bottom(700);
          }
        }
        if (canvas_result.getContext) {
          ctx_result.putImageData(imagedata, 0, work_height * number);
        }
      } else {
        $(".load_info_" + number).height(progress + '%');
        $(".load_info_" + number).text(progress + '%');
      }
    };
    workers = [];
    num_workers = pending_workers = $("#workers").val() || count_workers[number_test].toString();
    radius = $("#radius").val() || radius;
    $("#load_info").empty();
    for (i = _i = 0; 0 <= num_workers ? _i < num_workers : _i > num_workers; i = 0 <= num_workers ? ++_i : --_i) {
      js_class = "load_info_" + i;
      $("#load_info").append('\
        <div class="progress progress-striped active">\
          <div class="progress-bar ' + js_class + '" role="progressbar" aria-valuenow="45" aria-valuemin="0" aria-valuemax="100" style="height: 0%">\
          </div>\
        </div>');
    }
    $(".progress").width(($(".container").width() - num_workers * 5) / num_workers);
    console.time("DEBUG:: TIME create Worker LOOP");
    for (i = _j = 0; 0 <= num_workers ? _j < num_workers : _j > num_workers; i = 0 <= num_workers ? ++_j : --_j) {
      workers[i] = new Worker("worker.js");
      workers[i].onmessage = callback;
    }
    console.timeEnd("DEBUG:: TIME create Worker LOOP");
    /**
      Высота для одного Worker'a
      если высота получилась дробная округляем её в большую сторону
    */

    work_height = Math.ceil(canvas.height / num_workers);
    /**
      getImageData - долгая операция, поэтому результат
      лучше хранить в отдельном массиве
    */

    imagedata_work = [];
    imagedata_result = [];
    for (i = _k = 0; 0 <= num_workers ? _k < num_workers : _k > num_workers; i = 0 <= num_workers ? ++_k : --_k) {
      if (i) {
        imagedata_work[i] = ctx.getImageData(0, work_height * i - radius, canvas.width, work_height + radius);
        imagedata_result[i] = ctx.getImageData(0, 0, canvas.width, work_height);
      } else {
        imagedata_work[i] = ctx.getImageData(0, 0, canvas.width, work_height + radius);
        imagedata_result[i] = ctx.getImageData(0, 0, canvas.width, work_height);
      }
    }
    time = Date.now();
    console.time("DEBUG:: TIME postMesage LOOP");
    for (i = _l = 0; 0 <= num_workers ? _l < num_workers : _l > num_workers; i = 0 <= num_workers ? ++_l : --_l) {
      workers[i].postMessage({
        imagedata_work: imagedata_work[i],
        imagedata_result: imagedata_result[i],
        width: canvas.width,
        height_end: work_height + 2 * radius,
        radius: radius,
        number: i
      });
    }
    console.timeEnd("DEBUG:: TIME postMesage LOOP");
  } else {
    alert("Ваш браузер не поддерживает Web Workers!");
  }
};

chart = function() {
  $("#chart").highcharts({
    chart: {
      type: "column",
      margin: [50, 50, 100, 80]
    },
    title: {
      text: "Operation time Web Workers"
    },
    xAxis: {
      categories: label_workers,
      labels: {
        rotation: -45,
        align: "right",
        style: {
          fontSize: "13px",
          fontFamily: "Verdana, sans-serif"
        }
      }
    },
    yAxis: {
      min: 0,
      title: {
        text: "Time (milliseconds)"
      }
    },
    legend: {
      enabled: false
    },
    tooltip: {
      pointFormat: "Time: <b>{point.y} milliseconds</b>"
    },
    series: [
      {
        name: "Population",
        data: time_workers,
        dataLabels: {
          enabled: true,
          rotation: -90,
          color: "#FFFFFF",
          align: "right",
          x: 4,
          y: 10,
          style: {
            fontSize: "13px",
            fontFamily: "Verdana, sans-serif",
            textShadow: "0 0 3px black"
          }
        }
      }
    ]
  });
};

scroll_to_bottom = function(speed) {
  var height;
  height = $("body").height();
  $("html,body").animate({
    scrollTop: height
  }, speed);
};
