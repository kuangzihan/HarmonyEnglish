import promptAction from '@ohos.promptAction'
import router from '@ohos.router'
import emitter from '@ohos.events.emitter'
import { AnswerStatus } from '../enums/AnswerStatus'
import { OptionStatus } from '../enums/OptionsStatus'
import { PracticeStatus } from '../enums/PracticeStatus'
import { createPost } from '../http/Api'
import { getRandomQuestions, Question } from '../model/Question'
import { convertMillisecondsToTime } from '../utils/DateUtils'

@Component
export struct PracticePage {
  // 题总数
  @State totalCount: number = 10
  // 练习状态
  @State practiceStatus: PracticeStatus = PracticeStatus.Stopped
  // 数据源
  @State questions: Question[] = getRandomQuestions(this.totalCount)
  // 当前index
  @State currentIndex: number = 0
  // 答题状态
  @State answerStatus: AnswerStatus = AnswerStatus.Answering
  // 选择的选项
  @State selectedOption: string = ''
  // 本轮测试已作答个数
  @State answeredCount: number = 0
  // 正确个数
  @State rightCount: number = 0
  // 定时器
  timerController: TextTimerController = new TextTimerController();
  @State timeUsed: number = 0
  // 完成
  dialogcontroller: CustomDialogController = new CustomDialogController({
    builder: ResultDialog({
      answeredCount: this.answeredCount,
      rightCount: this.rightCount,
      timeUsed: this.timeUsed,
      resetPractice: () => {
        this.questions = getRandomQuestions(this.totalCount)
        this.currentIndex = 0
        this.answeredCount = 0
        this.rightCount = 0
        this.timeUsed = 0
        this.timerController.reset()
        this.answerStatus = AnswerStatus.Answering
      },
      startPractice: () => {
        this.startPractice()
      }
    }),
    customStyle: true,
    autoCancel: false
  })

  // 开始测试
  startPractice() {
    this.practiceStatus = PracticeStatus.Running
    // 启动定时器
    this.timerController.start()
  }

  // 暂停测试
  pausedPractice() {
    this.practiceStatus = PracticeStatus.Paused
    // 停止定时器
    this.timerController.pause()
  }

  // 结束测试
  stopPractice() {
    this.practiceStatus = PracticeStatus.Stopped
    // 停止定时器
    this.timerController.pause()
    // 弹窗
    this.dialogcontroller.open()
  }

  build() {
    Column() {
      // 统计信息
      Column() {
        // 准确率
        StatItem({
          icon: $r('app.media.ic_accuracy'),
          name: '准确率',
          fontColor: Color.Black
        }) {
          Text((this.answeredCount === 0 ? 0 : (this.rightCount / this.answeredCount * 100).toFixed()) + '%')
            .width(100)
            .textAlign(TextAlign.Center)
        }

        // 进度
        StatItem({
          icon: $r('app.media.ic_progress'),
          name: '进度',
          fontColor: Color.Black
        }) {
          Progress({
            value: this.answeredCount,
            total: this.totalCount
          }).width(100)
        }

        // 个数
        StatItem({
          icon: $r('app.media.ic_count'),
          name: '个数',
          fontColor: Color.Black
        }) {
          Button(this.totalCount.toString())
            .width(100)
            .height(25)
            .backgroundColor('#EBEBEB')
            .fontColor(Color.Black)
            .enabled(this.practiceStatus === PracticeStatus.Stopped)
            .opacity(this.practiceStatus === PracticeStatus.Stopped ? 1 : 0.3)
            .onClick(() => {
              TextPickerDialog.show({
                range: ['5', '10', '15', '20', '25', '30'],
                value: this.totalCount.toString(),
                onAccept: (result:TextPickerResult) => {
                  let value = result.value as string
                  this.totalCount = parseInt(value)
                  // 刷新题目
                  this.questions = getRandomQuestions(this.totalCount)
                }
              })
            })
        }

        // 用时
        StatItem({
          icon: $r('app.media.ic_timer'),
          name: '用时',
          fontColor: Color.Black
        }) {
          Row() {
            TextTimer({
              controller: this.timerController
            }).onTimer((utc: number, elapsedTime: number) => {
              console.log(`utc: ${utc}, elapsedTime: ${elapsedTime}`)
              this.timeUsed = elapsedTime
            })
          }
          .width(100)
          .justifyContent(FlexAlign.Center)
        }

      }.statBgStyle()

      // 题目
      Column() {
        Text(this.questions[this.currentIndex].word)
          .wordStyle()
        Text(this.questions[this.currentIndex].sentence)
          .sentenceStyle()
      }

      // 选项
      Column({ space: 10 }) {
        ForEach(this.questions[this.currentIndex].options, (option: string) => {
          OptionButton({
            option: option, // 选项字符串
            answer: this.questions[this.currentIndex].answer, // 正确答案字符串
            selectedOption: this.selectedOption,
            answerStatus: this.answerStatus
          })
            .enabled(this.answerStatus === AnswerStatus.Answering)
            .onClick(() => {


              // 判断联系状态
              if (this.practiceStatus !== PracticeStatus.Running) {
                promptAction.showToast({ message: "请先点击开始测试" })
                return
              }

              // 判断正误
              this.selectedOption = option

              // todo: 更新统计信息
              this.answeredCount++
              if (this.selectedOption === this.questions[this.currentIndex].answer) {
                this.rightCount++
              }

              // 切换题目
              if (this.currentIndex < this.questions.length - 1) {
                this.answerStatus = AnswerStatus.Answered
                setTimeout(() => {
                  this.currentIndex++
                  this.answerStatus = AnswerStatus.Answering
                }, 500)
              } else {
                this.stopPractice()
              }

            })
        }, (item: string, index: number) => this.questions[this.currentIndex].word + '-' +
          item) // ForEach 的第三个参数，每当它改变的时候就重新渲染

      }

      // 控制按钮
      Row({ space: 50 }) {
        Button("结束测试")
          .controlButtonStyle({
            bg: Color.Transparent,
            border: Color.Black,
            font: Color.Black
          })
          .opacity(this.practiceStatus === PracticeStatus.Stopped ? 0.2 : 1)
          .enabled(this.practiceStatus !== PracticeStatus.Stopped)
          .onClick(() => {
            this.stopPractice()
          })

        Button(this.practiceStatus === PracticeStatus.Running ? "暂停测试" : "开始测试")
          .controlButtonStyle({
            bg: this.practiceStatus === PracticeStatus.Running ? '#555555' : Color.Black,
            border: this.practiceStatus === PracticeStatus.Running ? '#555555' : Color.Black,
            font: Color.White
          })
          .stateEffect(false)// 不开启点击效果
          .onClick(() => {
            if (this.practiceStatus === PracticeStatus.Running) {
              this.pausedPractice()
            } else {
              this.startPractice()
            }
          })
      }

    }.practiceBgStyle()
  }
}


@Component
struct OptionButton {
  option: string = '' // 选项字符串
  answer: string = '' // 正确答案字符串
  // Prop 变量的更新顺序和声明顺序是一样的，因此 answerStatus 应该在 selectedOption 之后声明
  @Prop selectedOption: string // 用户选择的选项
  @Prop @Watch('onAnswerStatusChange') answerStatus: AnswerStatus // 作答状态
  @State optionStatus: OptionStatus = OptionStatus.Default

  onAnswerStatusChange() {
    if (this.option === this.answer) { // 自己是正确答案，改为绿色
      this.optionStatus = OptionStatus.Right
    } else { // 自己不是正确答案
      if (this.option === this.selectedOption) { // 自己是用户选择的选项，改为红色
        console.log("点错了");
        this.optionStatus = OptionStatus.Wrong
      } else { // 自己不是用户选择的选项，不改变样式
        this.optionStatus = OptionStatus.Default
      }
    }
  }

  // 背景颜色
  getBgColor() {
    switch (this.optionStatus) {
      case OptionStatus.Right:
        return '#1DBF7B'
      case OptionStatus.Wrong:
        return '#FA635F'
      default:
        return Color.White
    }
  }

  // 字体颜色
  getFontColor() {
    switch (this.optionStatus) {
      case OptionStatus.Right:
      case OptionStatus.Wrong:
        return Color.White
      default:
        return Color.Black
    }
  }

  build() {
    Stack() {
      Button(this.option)
        .optionButtonStyle({
          bg: this.getBgColor(),
          font: this.getFontColor()
        })

      if (this.optionStatus === OptionStatus.Right) {
        Image($r('app.media.ic_right'))
          .width(22)
          .height(22)
          .offset({ x: 10 })
      } else if (this.optionStatus === OptionStatus.Wrong) {
        Image($r('app.media.ic_wrong'))
          .width(22)
          .height(22)
          .offset({ x: 10 })
      }
    }.alignContent(Alignment.Start)
  }
}


@Component
export struct StatItem {
  icon?: Resource
  name: string = ''
  @BuilderParam statComp: () => void
  fontColor?: Color

  build() {
    Row({ space: 5 }) {
      Image(this.icon)
        .height(14)
        .width(14)
      Text(this.name)
        .fontWeight(FontWeight.Medium)
        .fontSize(14)
        .fontColor(this.fontColor)
      Blank() // 视图顶到右边
      this.statComp()
    }
    .width('100%')
    .height(30)
  }
}


@CustomDialog
struct ResultDialog {
  answeredCount: number = 0
  rightCount: number = 0
  timeUsed: number = 0
  resetPractice?: () => void
  startPractice?: () => void
  controller: CustomDialogController = new CustomDialogController({
    builder: ResultDialog()
  })
  @StorageProp('token') token: string = ''
  @StorageLink('currentTabIndex') currentTabIndex: number = 0

  build() {
    Column({ space: 10 }) {
      Image($r('app.media.ic_close'))
        .width(25)
        .height(25)
        .alignSelf(ItemAlign.End)
        .onClick(() => {
          this.controller.close()

          if (this.resetPractice) {
            this.resetPractice()
          }
        })

      Column({ space: 10 }) {
        Image($r('app.media.img_post'))
          .width('100%')
          .borderRadius(10)

        // 用时
        StatItem({
          icon: $r('app.media.ic_timer'),
          name: '用时',
          fontColor: Color.Black
        }) {
          Text(convertMillisecondsToTime(this.timeUsed))
        }

        // 准确率
        StatItem({
          icon: $r('app.media.ic_accuracy'),
          name: '准确率',
          fontColor: Color.Black
        }) {
          Text((this.answeredCount === 0 ? 0 : (this.rightCount / this.answeredCount * 100).toFixed()) + '%')
        }

        // 个数
        StatItem({
          icon: $r('app.media.ic_count'),
          name: '个数',
          fontColor: Color.Black
        }) {
          Text(this.answeredCount.toString())
        }

        Divider()

        Row({ space: 30 }) {
          Button('再来一局')
            .controlButtonStyle({
              bg: Color.Transparent,
              border: Color.Black,
              font: Color.Black
            })
            .onClick(() => {
              this.controller.close()

              if (this.resetPractice) {
                this.resetPractice()
              }
              if (this.startPractice) {
                this.startPractice()
              }
            })

          Button(this.token ? '立即打卡' : '登录打卡')
            .controlButtonStyle({
              bg: Color.Black,
              border: Color.Black,
              font: Color.White
            })
            .onClick(async () => {
              this.controller.close()

              if (this.resetPractice) {
                this.resetPractice()
              }
              if (this.token) {
                // 发送打卡请求
                await createPost({
                  rightCount: this.rightCount,
                  answeredCount: this.answeredCount,
                  timeUsed: this.timeUsed
                })
                promptAction.showToast({ message: '打卡成功' })
                // 通知
                emitter.emit({ eventId: 1 })
                // 跳转打卡圈
                this.currentTabIndex = 1
              } else {
                // 跳转登录
                router.pushUrl({
                  url: 'pages/LoginPage',
                  params: {
                    rightCount: this.rightCount,
                    answeredCount: this.answeredCount,
                    timeUsed: this.timeUsed
                  }
                })
              }
            })
        }
      }
      .backgroundColor(Color.White)
      .width('100%')
      .padding(20)
      .borderRadius(10)
    }
    .backgroundColor(Color.Transparent)
    .width('80%')
  }
}


// 页面背景
@Extend(Column)
function practiceBgStyle() {
  .width('100%')
  .height('100%')
  .backgroundImage($r('app.media.img_practice_bg'))
  .backgroundImageSize({ width: '100%', height: '100%' })
  .justifyContent(FlexAlign.SpaceEvenly)
}

// 统计面板背景
@Extend(Column)
function statBgStyle() {
  .backgroundColor(Color.White)
  .width('90%')
  .padding(20)
  .borderRadius(12)
}

// 单词
@Extend(Text)
function wordStyle() {
  .fontSize(50)
  .fontWeight(FontWeight.Bolder)
}

// 例句
@Extend(Text)
function sentenceStyle() {
  .height(40)
  .fontSize(16)
  .fontColor('#9BA1A5')
  .fontWeight(FontWeight.Medium)
  .width('80%')
  .textAlign(TextAlign.Center)
}


// 选项按钮
interface optionButtonStyleData {
  bg: ResourceColor,
  font: ResourceColor
}

@Extend(Button)
function optionButtonStyle(color: optionButtonStyleData) {
  .type(ButtonType.Normal)
  .width(240)
  .height(48)
  .fontSize(16)
  .fontWeight(FontWeight.Medium)
  .borderRadius(8)
  .backgroundColor(color.bg)
  .fontColor(color.font)
}


// 控制按钮

interface ControlButtonData {
  bg: ResourceColor;
  border: ResourceColor;
  font: ResourceColor;
}

@Extend(Button)
function controlButtonStyle(color: ControlButtonData) {
  .fontSize(16)
  .borderWidth(1)
  .fontColor(color.font)
  .borderColor(color.border)
  .backgroundColor(color.bg)
}