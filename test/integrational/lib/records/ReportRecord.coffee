

module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    TimestampsArrayTransform
    Utils: { joi }
  } = Module::

  class ReportRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    # Place for attributes and computeds definitions
    @attribute dateSince: Date,
      validate: -> joi.date().iso().required()
    @attribute dateTill: Date,
      validate: -> joi.date().iso().required()
    @attribute dateYear: Number,
      validate: -> joi.number().empty(null).default(null)
    @attribute dateWeek: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute dateMonth: Number,
      validate: -> joi.number().empty(null).default(null)
    @attribute dateDay: Number,
      validate: -> joi.number().empty(null).default(null)
    @attribute dateHour: Number,
      validate: -> joi.number().empty(null).default(null)
    @attribute dateMinute: Number,
      validate: -> joi.number().empty(null).default(null)

    @attribute typeRate: Array,
      transform: -> TimestampsArrayTransform
      validate: -> joi.array().items joi.number().empty(null).default(null)
    @attribute clickRate: Array,
      transform: -> TimestampsArrayTransform
      validate: -> joi.array().items joi.number().empty(null).default(null)
    @attribute tapRate: Array,
      transform: -> TimestampsArrayTransform
      validate: -> joi.array().items joi.number().empty(null).default(null)
    @attribute screenshots: Array,
      validate: -> joi.array().items joi.string().empty(null).default(null)
    @attribute snapshots: Array,
      validate: -> joi.array().items joi.string().empty(null).default(null)
    @attribute apps: Array,
      validate: -> joi.array().items joi.object(
        sid:    joi.string()
        pid:    joi.number()
        exec:   joi.string()
        cmd:    joi.string()
        name:   joi.string()
        title:  joi.string()
        ts:     joi.number()
        d:      joi.number()
      ).empty(null).default(null)
    @attribute intensityRate: Number,
      validate: ->
        joi.number().empty(null).default(0, 'by default').only [0..10]
    @attribute latitude: Number,
      validate: -> joi.number().empty(null).default(null, 'by default')
    @attribute longitude: Number,
      validate: -> joi.number().empty(null).default(null, 'by default')

    @attribute ipAddress: String,
      validate: -> joi.string().empty(null).default(null, 'by default')
    @attribute customPlaceLabel: String,
      validate: -> joi.string().empty(null).default(null, 'by default')
    @attribute customPlaceAddress: String,
      validate: -> joi.string().empty(null).default(null, 'by default')
    @attribute device: String, # так как и в мануальном и в автоматическом репорте должно быть поле с произвольной строкой. - сервер никак на это не реагирует, т.к. там произвольный текст. - что с++ клиент и веб-клиент решат там хранить, то и будет там.
      validate: -> joi.string().empty(null).default(null, 'by default')

    @attribute taskId: String,
      validate: -> joi.string().empty(null).default(null)

    @belongsTo client: RecordInterface,
      validate: -> joi.string().required()
    @attribute spaces: Array,
      validate: -> joi.array().items joi.string().empty(null).default(null)
    @belongsTo creator: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo editor: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo remover: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo owner: RecordInterface,
      transform: -> @Module::UserRecord

    @beforeHook 'calculateIntensityRate', only: ['create', 'update']

    # business logic and before-, after- colbacks
    @public @async calculateIntensityRate: Function,
      default: (args...)->
        {maxTotalClicksForIntensityRate: maxTotalClicks} = @collection.configs
        typeRate = @typeRate ? []
        clickRate = @clickRate ? []
        tapRate = @tapRate ? []
        totalClicks = typeRate.length + clickRate.length + tapRate.length
        @intensityRate = if totalClicks >= maxTotalClicks
          10
        else
          Math.round totalClicks / maxTotalClicks * 10
        yield return args


  ReportRecord.initialize()
