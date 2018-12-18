

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
    @attribute dateYear: Number
    @attribute dateWeek: String
    @attribute dateMonth: Number
    @attribute dateDay: Number
    @attribute dateHour: Number
    @attribute dateMinute: Number

    @attribute typeRate: Array,
      transform: -> TimestampsArrayTransform
    @attribute clickRate: Array,
      transform: -> TimestampsArrayTransform
    @attribute tapRate: Array,
      transform: -> TimestampsArrayTransform
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
    @attribute latitude: Number
    @attribute longitude: Number

    @attribute ipAddress: String
    @attribute customPlaceLabel: String
    @attribute customPlaceAddress: String
    @attribute device: String # так как и в мануальном и в автоматическом репорте должно быть поле с произвольной строкой. - сервер никак на это не реагирует, т.к. там произвольный текст. - что с++ клиент и веб-клиент решат там хранить, то и будет там.

    @attribute taskId: String
    @attribute clientId: String,
      validate: -> joi.string().required()
    @attribute spaces: Array,
      validate: -> joi.array().items joi.string().empty(null).default(null)
    @attribute creatorId: String
    @attribute editorId: String
    @attribute removerId: String
    @attribute ownerId: String

    @relatedTo client: RecordInterface

    @relatedTo creator: RecordInterface,
      recordName: -> 'UserRecord'
    @relatedTo editor: RecordInterface,
      recordName: -> 'UserRecord'
    @relatedTo remover: RecordInterface,
      recordName: -> 'UserRecord'
    @relatedTo owner: RecordInterface,
      recordName: -> 'UserRecord'

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


    @initialize()
